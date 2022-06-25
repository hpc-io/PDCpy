cimport pdc.cpdc as cpdc
from pdc.cpdc cimport uint32_t, uint64_t, pdc_var_type_t, pdc_lifetime_t, pdc_access_t, pdc_query_combine_op_t, pdc_query_op_t
import atexit
from typing import Optional, Tuple, List, TypeVar, Generic, Iterable, NewType
from enum import Enum
import os
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
from functools import singledispatchmethod
import builtins
import numpy as np
import numpy.typing as npt
from abc import ABC, abstractmethod
from weakref import finalize
import collections.abc

int32 = NewType('int32', int)
uint32 = NewType('uint32', int)
uint64 = NewType('uint64', int)
pdcid = NewType('pdcid', int)

cdef void *malloc_or_memerr(size_t size):
    cdef void *ptr = malloc(size)
    if not ptr:
        raise MemoryError()
    return ptr

def _free_from_int(ptr: int):
    cdef size_t cptr
    if ptr:
        cptr = ptr
        free(<void *> cptr)

class PDCError(Exception):
    '''
    A general error type for all errors in the pdc api.
    '''
    pass

class InternalPDCError(Exception):
    '''
    Indicates an error internal to the python interface.  If you see this error, report it.
    '''
    pass

_is_open = False

def _get_pdcid() -> pdcid:
    global pdc_id
    return pdc_id

def init(name:str="PDC"):
    '''
    Initialize PDC.
    This call will block and eventually terminate the program if the PDC server is not running.
    This must be called before any other PDC method.
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

class KVTags(ABC):
    '''
    An object used to manipulate object and container tags.
    Supports the following operations:

    =================== ==============================
    example             effect
    =================== ==============================
    ``value = tags[x]`` get the value of the tag ``x``
    ``tags[x] = value`` set the value of the tag ``x``
    ``del tags[x]``     delete the tag ``x``
    =================== ==============================
    '''

    def __getitem__(self, name:str):
        pass
    
    def __setitem__(self, name:str, value:object):
        pass
    
    def __delitem__(self, name:str):
        pass