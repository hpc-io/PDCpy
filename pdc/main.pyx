cimport pdc.cpdc as cpdc
from pdc.cpdc cimport pdc_var_type_t
from typing import TypeVar, Generic, NewType
from enum import Enum
import os
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
import numpy as np
from abc import ABC
from weakref import finalize
import shutil
from subprocess import Popen, PIPE

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

def _get_pdcid():
    global pdc_id
    return pdc_id

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

class ServerContext:
    '''
    A context manager that starts and stops a single PDC server instance on enter and exit
    This is intended for testing
    '''
    def __enter__(self):
        path = shutil.which('pdc_server.exe')
        if not path:
            raise FileNotFoundError('pdc_server.exe not on PATH')
        self.popen = Popen([path], stdout=PIPE, encoding='ascii', text=True)
        for line in self.popen.stdout:
            if 'Server ready' in line:
                break
        else:
            raise PDCError('Could not start PDC server')
        return self
    
    def __exit__(self, exc_type, exc_value, traceback):
        self.popen.kill()
        self.popen.wait()
        return False

def checktype(value, name, expected):
    if not isinstance(value, expected):
        raise TypeError(f'invalid type of {name}: {type(value)}, expected {expected.__name__}')

def checkrange(value, name, expected:str):
    if expected == 'uint32':
        if value < 0 or value > 0xFFFFFFFF:
            raise OverflowError(f'{name} is out of range for uint32: {value}')
    elif expected == 'uint64':
        if value < 0 or value > 0xFFFFFFFFFFFFFFFF:
            raise OverflowError(f'{name} is out of range for uint64: {value}')
    elif expected == 'int32':
        if value < -0x7FFFFFFF or value > 0x7FFFFFFF:
            raise OverflowError(f'{name} is out of range for int32: {value}')
    else:
        raise ValueError(f'invalid value for expected range: {expected}')