import abc
import collections.abc
from abc import ABC, abstractmethod
from typing import TypeVar, Iterable, Tuple
from enum import Enum

import numpy.typing as npt

from pdc.cpdc cimport pdc_query_combine_op_t, pdc_query_op_t, pdc_kvtag_t, uint64_t
cimport pdc.cpdc as cpdc
from .main import PDCError, checktype, KVTags
from . import object

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
        
        def __iter__(self) -> Iterable['Object']:
            pass
        
        def __len__(self) -> int:
            pass

    class _CombineOp(Enum):
        NONE = pdc_query_combine_op_t.PDC_QUERY_NONE
        AND = pdc_query_combine_op_t.PDC_QUERY_AND
        OR = pdc_query_combine_op_t.PDC_QUERY_OR
    
    @staticmethod
    def _from_comparison(obj:'Object', op:'QueryComponent._CompareOp') -> 'Query':
        pass
    
    def _combine(self: 'Query', other: 'Query', op:_CombineOp) -> 'Query':
        pass
    
    def __and__(self, other: 'Query') -> 'Query':
        return self.combine(other, Query._CombineOp.AND)
    
    def __or__(self, other: 'Query') -> 'Query':
        return self.combine(other, Query._CombineOp.OR)
    
    def get_num_hits(self, region:'Region' = None) -> int:
        '''
        Get number of hits for this query (i.e. number of elements that match this query)

        :param Region region: The region to query over.  If this is None, the entire object is queried.
        :return: number of hits
        :rtype: int
        '''
        pass
    
    def get_result(self, region:'Region' = None) -> Result:
        '''
        Get the result of this query

        :param Region region: The region to query over.  If this is None, the entire object is queried.
        :return: the result
        :rtype: Result
        '''
        pass
    
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
    
    def _compare(self, other:object, op:'_CompareOp') -> Query:
        checktype(op, type(self)._CompareOp)
        return Query._from_comparison(self._obj, op)
    
    def __gt__(self, other:object) -> Query:
        return self._compare(other, type(self)._CompareOp.GT)
    
    def __lt__(self, other:object) -> Query:
        return self._compare(other, type(self)._CompareOp.LT)
    
    def __ge__(self, other:object) -> Query:
        return self._compare(other, type(self)._CompareOp.GTE)
    
    def __le__(self, other:object) -> Query:
        return self._compare(other, type(self)._CompareOp.LTE)
    
    def __eq__(self, other:object) -> Query:
        return self._compare(other, type(self)._CompareOp.EQ)


def tag_query(tag_name:str, tag_value:str) -> Tuple['Object']:
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