import abc
import collections.abc
from abc import ABC, abstractmethod
from typing import TypeVar, Iterable
from enum import Enum

import numpy.typing as npt

from pdc.cpdc cimport pdc_query_combine_op_t, pdc_query_op_t

class Query(ABC):
    class _CombineOp(Enum):
        NONE = pdc_query_combine_op_t.PDC_QUERY_NONE
        AND = pdc_query_combine_op_t.PDC_QUERY_AND
        OR = pdc_query_combine_op_t.PDC_QUERY_OR
    
    @abstractmethod
    def _combine(self: 'Query', other: 'Query', op:_CombineOp) -> 'Query':
        pass
    
    def __and__(self, other: 'Query') -> 'Query':
        return self.combine(other, Query._CombineOp.AND)
    
    def __or__(self, other: 'Query') -> 'Query':
        return self.combine(other, Query._CombineOp.OR)
    
Q = TypeVar('Q', bound=Query)

class QueryComponent(ABC):
    class _CompareOp(Enum):
        OP_NONE = pdc_query_op_t.PDC_OP_NONE
        GT = pdc_query_op_t.PDC_GT
        LT = pdc_query_op_t.PDC_LT
        GTE = pdc_query_op_t.PDC_GTE
        LTE = pdc_query_op_t.PDC_LTE
        EQ = pdc_query_op_t.PDC_EQ
    
    @abstractmethod
    def _compare(self, other:object, op:_CompareOp) -> Q:
        pass
    
    def __gt__(self, other:object) -> Query:
        return self._compare(other, QueryComponent._CompareOp.GT)
    
    def __lt__(self, other:object) -> Query:
        return self._compare(other, QueryComponent._CompareOp.LT)
    
    def __ge__(self, other:object) -> Query:
        return self._compare(other, QueryComponent._CompareOp.GTE)
    
    def __le__(self, other:object) -> Query:
        return self._compare(other, QueryComponent._CompareOp.LTE)
    
    def __eq__(self, other:object) -> Query:
        return self._compare(other, QueryComponent._CompareOp.EQ)

class DataQueryComponent:
    def _compare(self, other:object, op:QueryComponent._CompareOp) -> 'DataQuery':
        pass

class DataQuery(Query, collections.abc.Mapping):
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

    def _combine(self: Q, other:Q, op:Query._CombineOp) -> Q:
        pass
    
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
