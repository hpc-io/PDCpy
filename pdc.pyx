cimport cpdc
from cpdc cimport uint32_t, uint64_t, pdc_var_type_t, pdc_lifetime_t, pdc_access_t, pdc_query_combine_op_t, pdc_query_op_t
import atexit
from typing import Optional, Tuple, List, TypeVar, Generic
from enum import Enum
import os
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
from functools import singledispatchmethod
import builtins
import numpy as np
import numpy.typing as npt
from abc import ABC, abstractmethod
from weakref import finalize

int32 = int
uint32 = int
uint64 = int
pdcid = int

cdef void *malloc_or_memerr(size_t size):
    cdef void *ptr = malloc(size)
    if not ptr:
        raise MemoryError()
    return ptr

class PDCError(Exception):
    pass

_is_open = False

def init(name:str="PDC"):
    '''
    Initialize PDC
    This call will block and eventually terminate the program if the PDC server is not running.
    This must be called before anything else
    '''
    global pdc_id, _is_open
    name_bytes = name.encode('utf-8')
    pdc_id = cpdc.PDCinit(name_bytes)
    if not pdc_id:
        raise PDCError('Could not initialize PDC')
    
    #hack to ensure close runs after all finalizers
    #See: https://stackoverflow.com/questions/72622803/how-do-i-make-an-exit-handler-that-runs-after-all-weakref-finalizers-run
    finalize(_close, _close, pdc_id)
    _is_open = True

def _close(pdc_id):
    global _is_open
    if not _is_open:
        return
    err = cpdc.PDCclose(pdc_id)
    if err < 0:
        raise PDCError('Could not close PDC')
    _is_open = False

def ready() -> bool:
    '''
    True if init() has been called, False otherwise
    '''
    return _is_open


class Type(Enum):
    '''
    All of the data types that PDC objects support
    '''

    INT      = pdc_var_type_t.PDC_INT
    '''
    A signed int with the system's default width.  This is the default value for Type aguments
    '''
    FLOAT    = pdc_var_type_t.PDC_FLOAT
    '''
    A 32-bit float
    '''
    DOUBLE   = pdc_var_type_t.PDC_DOUBLE
    '''
    A 64-bit float
    '''
    CHAR     = pdc_var_type_t.PDC_CHAR
    '''
    An 8-bit character
    '''
    UINT     = pdc_var_type_t.PDC_UINT
    '''
    A signed int with the system's default width.
    '''
    INT64    = pdc_var_type_t.PDC_INT64
    '''
    A 64-bit signed integer
    '''
    UINT64   = pdc_var_type_t.PDC_UINT64
    '''
    A 64-bit unsigned integer
    '''
    INT16    = pdc_var_type_t.PDC_INT64
    '''
    A 16-bit signed integer
    '''
    INT8     = pdc_var_type_t.PDC_INT8
    '''
    An 8-bit signed integer
    '''

class Container:
    '''
    A PDC container
    '''

    class Lifetime(Enum):
        '''
        An emuneration of the lifetimes of containers.
        '''
        PERSISTENT = pdc_lifetime_t.PDC_PERSIST
        TRANSIENT  = pdc_lifetime_t.PDC_TRANSIENT

    
    def __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT):
        '''
        :param str name: the name of the container.  Container names should be unique between all processes that use PDC.
        :param :ifetime lifetime: the conteiner's lifetime.
        '''
        pass
    
    def persist():
        '''
        Make this container persistent if it wasn't already.
        '''
        pass

class Object:
    '''
    A PDC object
    '''

    @property
    def properties(self) -> 'Properties':
        '''
        The properties of this object.  read-only
        '''
        pass
    
    @property
    def name(self) -> str:
        '''
        The name of this object. read-only
        '''
        pass

    class Properties:
        '''
        Contains most of the metadata associated with an object.
        This is an inner class of Object
        '''

        _dims:Tuple[int]
        _type:Type
        _time_step:uint32
        _user_id:uint32
        _app_name:str
        prop_id:pdcid

        _dims_ptr:uint64

        def __init__(self, dims:Tuple[int], type:Type=Type.INT, uint32_t time_step:uint32=0, user_id:Optional[uint32]=None, str app_name:str=''):
            '''
            :param dims: A tuple containing dimensions of the object.  For example, (10, 3) means 10 rows and 3 columns.  1 <= len(dims) <= 2^31-1 
            :type dims: Sequence[int]
            :param Type type: the data type.  Defaults to INT
            :param uint32 time_step: For applications that involve data along a time axis, this represents the point in time of the data.  Defaults to 0.
            :param uint32 user_id: the id of the user.  defaults to os.getuid()
            :param str app_name: the name of the application.  Defaults to an empty string.
            '''
            if user_id is None:
                user_id = os.getuid()
            
            global pdc_id
            self.prop_id = cpdc.PDCprop_create(cpdc.pdc_prop_type_t.PDC_OBJ_CREATE, pdc_id)        
            self.app_name = app_name
            self.type = type
            self.time_step = time_step
            self.user_id = user_id
        
        def _free_dims(self):
            cdef uint64_t ptr
            if self._dims_ptr:
                ptr = self._dims_ptr
                free(<uint64_t*> ptr)
        
        @property
        def dims(self) -> Tuple[int]:
            return self._dims
        
        @dims.setter
        def dims(self, dims:Tuple[int]):
            if not isinstance(dims, tuple):
                raise TypeError(f"invalid type of dims: {type(dims)}.  expected tuple")
            if not 1 <= len(dims) <= 2**31-1:
                raise ValueError('dims must be at most 2^31-1 elements long')
            
            cdef uint32_t length = len(dims)

            self._free_dims()
            cdef uint64_t *dims_ptr = <uint64_t*> malloc_or_memerr(length * sizeof(uint64_t))
            self._dims_ptr = <uint64_t> dims_ptr

            for i in range(length):
                dims_ptr[i] = dims[i]
            
            cpdc.PDCprop_set_obj_dims(self.prop_id, length, dims_ptr)

            self._dims = dims
        
        @property
        def type(self) -> Type:
            return self._type
        
        @type.setter
        def type(self, type:Type):
            if not isinstance(type, Type):
                raise TypeError(f"invalid type of type: {builtins.type(type)}.  Expected Type")
            
            cpdc.PDCprop_set_obj_type(self.prop_id, type.value)
        
        @property
        def time_step(self) -> uint32:
            return self._time_step
        
        @time_step.setter
        def time_step(self, uint32_t time_step:uint32):
            cdef uint32_t time_step_c = time_step
            cpdc.PDCprop_set_obj_time_step(self.prop_id, time_step_c)
        
        @property
        def user_id(self) -> uint32:
            '''
            the id of the user.
            '''
            pass
        
        @user_id.setter
        def user_id(self, uint32_t id:uint32):
            pass
        
        @property
        def app_name(self) -> str:
            '''
            The name of the application
            '''
            pass
        
        @app_name.setter
        def app_name(self, str name:str):
            pass
        
        def copy(self) -> 'Properties':
            '''
            Returns a copy of this Properties object
            '''
            pass

        def __del__(self):
            self._free_dims()
    
    class TransferRequest:
        '''
        Represents a transfer request to either set a region's data or get it
        This object can be awaited
        '''

        class RequestType(Enum):
            '''
            The type of transfer request
            '''
            GET = pdc_access_t.PDC_READ
            SET = pdc_access_t.PDC_WRITE

        def __await__(self):
            yield None
        
        @property
        def done(self) -> bool:
            '''
            True if this transfer request is completed
            '''
            return False
        
        @property
        def type(self) -> RequestType:
            '''
            Get the type of request
            '''
            pass
        
        @property
        def result(self) -> Optional[npt.NDArray]:
            '''
            If the request is done and the request type is RequestType.get, this is a numpy array containing the requested data.
            '''
            return None
    
    class Region:
        '''
        A region of an Object
        This is an inner class of Object
        '''
        
        @singledispatchmethod
        def __init__(self, slice, id):
            raise TypeError(f'invalid type of slice: {type(slice)}')
        
        @__init__.register
        def _(self, slice:int, id:pdcid):
            pass
        
        @__init__.register
        def _(self, slice:builtins.slice, id:pdcid):
            pass
        
        @__init__.register
        def _(self, slice:tuple, id:pdcid):
            pass
        
        def with_object(self, other:'Object') -> 'Region':
            '''
            Return a copy of this Region that is bound to `other` instead
            object1[x, y, z].with_object(object2)
            is equivalent to
            object2[x, y, z]
            '''
            pass
        
        def get(self) -> 'Object.TransferRequest':
            pass
        
        def set(self, data) -> 'Object.TransferRequest':
            pass
    
    @singledispatchmethod
    def __init__(self, name, *args):
        raise TypeError(f'Invalid type of name: {type(name)}')

    @__init__.register
    def _(self, name:str, properties:Properties, container:Container):
        '''
        Create a new object.  To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param ObjectProperties properties: An ObjectProperties describing the properties of the object
        :param Container container: the container this object should be placed in.
        '''
        pass
    
    @__init__.register
    def _(self, id:int):
        #create from id instead
        pass
    
    @staticmethod
    def get(name:str) -> 'Object':
        '''
        Get an existing object by name

        If you have created multiple objects with the same name, this will return the one with time_step=0
        If there are multiple objects with the same name and time_step, the tie is broken arbitrarily
        '''
        pass


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

class DataQuery(Query):
    class Result:
        '''
        Result of a DataQuery
        '''

    def _combine(self: Q, other:Q, op:Query._CombineOp) -> Q:
        pass
    
    def get_num_hits() -> int:
        '''
        Get number of hits for this query (i.e. number of objects that match this query)
        More efficient than len(query.get_result())
        '''
        pass
    
    def get_result() -> Result:
        '''
        Get the result of this query
        '''
        pass

class MetaDataQuery(Query):
    def _combine(self: Q, other:Q, op:Query._CombineOp) -> Q:
        pass
    
    def get_result(self) -> List[Object]:
        '''
        Get list of objects matching this query
        '''
        pass

class DataQueryComponent(QueryComponent):
    def _compare(self, other:object, op:QueryComponent._CompareOp) -> DataQuery:
        pass

class MetaDataQueryComponent(QueryComponent):
    def _compare(self, other:object, op:QueryComponent._CompareOp) -> MetaDataQuery:
        pass
