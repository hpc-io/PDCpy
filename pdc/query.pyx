import abc
import collections.abc
from abc import ABC, abstractmethod
from typing import TypeVar, Iterable, Tuple
from enum import Enum
from weakref import finalize
import builtins

import numpy.typing as npt

from pdc.cpdc cimport pdc_query_combine_op_t, pdc_query_op_t, pdc_kvtag_t, uint64_t, pdc_query_t, int16_t, int8_t, uint64_t, int64_t, pdc_selection_t, pdcid_t, pdc_region_info
cimport pdc.cpdc as cpdc
from .main import PDCError, checktype, KVTags, Type, uint64, ctrace, pdcid
from pdc.main cimport malloc_or_memerr
from .region import region, Region
from .region import region as region_
from pdc.region cimport construct_region_info, free_region_info

class Query(ABC):
    class Result:
        '''
        Result of a DataQuery

        To get results from this class, index it using objects as keys
        For example:
        ``query.get_result()[object1]``
        '''

        def __getitem__(self, obj: 'Object') -> npt.NDArray:
            pass
                
        def __init__(self, id:pdcid, query:'Query'):
            self._id = id
            finalize(self, type(self)._finalize, self._id)
            self._query = query
            self.hits = (<pdc_selection_t *> <size_t> id)[0].nhits
        
        @staticmethod
        def _finalize(id:pdcid):
            rtn = cpdc.PDCselection_free(<pdc_selection_t *> <size_t> id)
            ctrace('selection_free', rtn, id)
        

    class _CombineOp(Enum):
        NONE = pdc_query_combine_op_t.PDC_QUERY_NONE
        AND = pdc_query_combine_op_t.PDC_QUERY_AND
        OR = pdc_query_combine_op_t.PDC_QUERY_OR
    
    def __init__(self, id:uint64, op, left=None, right=None):
        self._id = id
        finalize(self, type(self)._finalize, self._id)
        self.op = op
        if left is not None and right is None:
            #leaf
            self._left = left
            self.objects = frozenset((left,))
            self.mindims = left.dims
            self.all_same = True
        else:
            #inner
            self._left = left
            self._right = right
            self.objects = left.objects | right.objects
            self.mindims = tuple(
                min(left.mindims[i], right.mindims[i])
                for i in range(len(left.mindims))
            )
            self.all_same = left.all_same and right.all_same and left.mindims == right.mindims
    
    @classmethod
    #TODO: add more specific type for other
    def _from_comparison(cls, obj:'Object', op:'QueryComponent._CompareOp', other:builtins.object) -> 'Query':
        obj_type = obj.type
        #trust op to be the right type
        cdef int int_
        cdef unsigned int uint_
        cdef float float_
        cdef double double_
        cdef int64_t int64_
        cdef uint64_t uint64_ 
        cdef int16_t int16_
        cdef int8_t int8_
        cdef void *ptr
        if obj_type in (Type.FLOAT, Type.DOUBLE):
            checktype(other, 'value', float)
        else:
            checktype(other, 'value', int)
        try:
            if obj_type == Type.INT32:
                int_ = other
                ptr = &int_
            elif obj_type == Type.UINT32:
                uint_ = other
                ptr = &uint_
            elif obj_type == Type.FLOAT:
                float_ = other
                ptr = &float_ 
            elif obj_type == Type.DOUBLE:
                double_ = other
                ptr = &double_ 
            elif obj_type == Type.INT64:
                int64_ = other
                ptr = &int64_ 
            elif obj_type == Type.UINT64:
                uint64_ = other
                ptr = &uint64_ 
            elif obj_type == Type.INT16:
                int16_ = other
                ptr = &int16_ 
            elif obj_type == Type.INT8:
                int8_ = other
                ptr = &int8_ 
            else:
                raise ValueError(f'Unknown PDC type: {obj_type.name}')
        except OverflowError:
            raise OverflowError(f'value {other} is not within the acceptable range for {obj_type.name}') from None
        cdef pdc_query_t *query_struct = cpdc.PDCquery_create(obj._id, op.value, obj_type.value, ptr)
        ctrace('query_create', <uint64_t> query_struct, obj._id, op.name, obj_type.name, other)
        if query_struct == NULL:
            raise PDCError('Failed to create query')
        
        return cls(<uint64_t> query_struct, op, obj)

    @staticmethod
    def _finalize(id):
        rtn = cpdc.PDCquery_free(<pdc_query_t *> <size_t> id)
        ctrace('query_free', rtn, id)

    def _combine(self, other: 'Query', op:_CombineOp) -> 'Query':
        cdef pdc_query_t *query_struct
        checktype(other, 'query', Query)
        if len(self.mindims) != len(other.mindims):
            raise ValueError('Cannot combine queries with different number of dimensions')

        if op == Query._CombineOp.OR:
            query_struct = cpdc.PDCquery_or(<pdc_query_t *> <size_t> self._id, <pdc_query_t *> <size_t> other._id)
            ctrace('query_or', <uint64_t> query_struct, self._id, other._id)
        elif op == Query._CombineOp.AND:
            query_struct = cpdc.PDCquery_and(<pdc_query_t *> <size_t> self._id, <pdc_query_t *> <size_t> other._id)
            ctrace('query_and', <uint64_t> query_struct, self._id, other._id)
        else:
            raise ValueError(f'Unknown comparison operator: {op.name}')
        
        if query_struct == NULL:
            raise PDCError(f'Failed to combine queries with {op.name}')
        
        return Query(<uint64_t> query_struct, op, self, other)
    
    def __and__(self, other: 'Query') -> 'Query':
        return self._combine(other, Query._CombineOp.AND)
    
    def __or__(self, other: 'Query') -> 'Query':
        return self._combine(other, Query._CombineOp.OR)
    
    def get_num_hits(self, region:'Region' = None) -> int:
        '''
        Get number of hits for this query (i.e. number of elements that match this query)

        :param Region region: The region to query over.  If this is None, the entire object is queried.
        :return: number of hits
        '''
        pass
    
    def get_result(self, region:'Region' = None) -> Result:
        '''
        Get the result of this query

        :param Region region: The region to query over.  If this is None, the entire object is queried.
        :return: the Result object
        '''
        cdef pdcid_t region_id
        cdef pdc_region_info *region_info
        if region is not None:
            if not self.all_same and not region.is_absolute():
                raise ValueError('Cannot query over a non-absolute region with objects of different dimensions')
            
            try:
                region_info = construct_region_info(region, self.mindims)
            except ValueError as e:
                raise ValueError(f'Region {region} is out of bounds for one or more objects in this query') from e
            
            try:
                rtn = cpdc.PDCquery_sel_region(<pdc_query_t *> <size_t> self._id, region_info)
                ctrace('query_sel_region', rtn, self._id, <size_t> region_info)
                if rtn != 0:
                    raise PDCError(f'Failed to select region {region} for query')
            finally:
                free_region_info(region_info)
        
        cdef pdc_selection_t *selection = <pdc_selection_t *> malloc_or_memerr(sizeof(pdc_selection_t))
        rtn = cpdc.PDCquery_get_selection(<pdc_query_t *> <size_t> self._id, selection)
        ctrace('query_get_selection', rtn, self._id, <size_t> selection)
        if rtn != 0:
            raise PDCError(f'Failed to get selection for query')
        
        return type(self).Result(<uint64_t> selection, self)

class QueryComponent:
    '''
    An object used to build a query
    '''

    class _CompareOp(Enum):
        OP_NONE = pdc_query_op_t.PDC_OP_NONE
        GT = pdc_query_op_t.PDC_GT
        LT = pdc_query_op_t.PDC_LT
        GTE = pdc_query_op_t.PDC_GTE
        LTE = pdc_query_op_t.PDC_LTE
        EQ = pdc_query_op_t.PDC_EQ
    
    def __init__(self, obj:'Object'):
        self._obj = obj
    
    def _compare(self, other:builtins.object, op:'_CompareOp') -> Query:
        checktype(op, 'comparison operator', type(self)._CompareOp)
        return Query._from_comparison(self._obj, op, other)
    
    def __gt__(self, other:builtins.object) -> Query:
        return self._compare(other, type(self)._CompareOp.GT)
    
    def __lt__(self, other:builtins.object) -> Query:
        return self._compare(other, type(self)._CompareOp.LT)
    
    def __ge__(self, other:builtins.object) -> Query:
        return self._compare(other, type(self)._CompareOp.GTE)
    
    def __le__(self, other:builtins.object) -> Query:
        return self._compare(other, type(self)._CompareOp.LTE)
    
    def __eq__(self, other:builtins.object) -> Query:
        return self._compare(other, type(self)._CompareOp.EQ)


def _tag_query(tag_name:str, tag_value:str) -> Tuple['Object']:
    '''
    Get objects with a tag of the given name and value
    CURRENTLY NOT IMPLEMENTED

    :param str tag_name: name of the tag
    :param str tag_value: value of the tag
    :return: objects with the given tag
    :rtype: Iterable[Object]
    '''
    raise NotImplementedError()
    '''
    checktype(tag_name, 'tag name', str)
    checktype(tag_value, 'tag value', str)

    cdef pdc_kvtag_t kvtag
    tag_name_bytes = tag_name.encode('utf-8')
    tag_value_bytes = KVTags._encode(tag_value)
    kvtag.name = tag_name_bytes
    kvtag.value = <char *> tag_value_bytes
    kvtag.size = len(tag_value_bytes)

    cdef int num_results
    cdef uint64_t *results
    if (cpdc.PDC_Client_query_kvtag(&kvtag, &num_results, &results) != 0):
        raise PDCError('Error querying for objects with tag {}={}'.format(tag_name, tag_value))
    
    rtn = tuple(object.Object._fromid(results[i]) for i in range(num_results))
    return rtn
    '''