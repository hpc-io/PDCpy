cimport pdc.cpdc as cpdc
from pdc.cpdc cimport pdc_var_type_t, int64_t, uint64_t, int16_t, int8_t
from typing import TypeVar, Generic, NewType, Union
from enum import Enum
import os
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
import numpy as np
from abc import ABC, abstractmethod
from weakref import finalize
import shutil
from subprocess import Popen, PIPE
import ast

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

ctrace_id_map = {}
term_color_map = {
    'red': '\033[31m',
    'green': '\033[32m',
    'yellow': '\033[33m',
    'blue': '\033[34m',
    'magenta': '\033[35m',
    'turquoise': '\033[36m'
}
term_color_end = '\033[0m'
last_color = None
do_ctrace = True
file_output = True
ctrace_file = None
def format_id(id):
    global last_color
    if id in ctrace_id_map:
        color = ctrace_id_map[id]
    elif last_color is None:
        color = 'red'
    else:
        colors = list(term_color_map.keys())
        color = colors[(colors.index(last_color) + 1) % len(colors)]
    
    ctrace_id_map[id] = color
    last_color = color
    return term_color_map[color] + str(id) + term_color_end
def format_arg(arg):
    if isinstance(arg, int) and arg > 100000:
        return format_id(arg)
    else:
        return str(arg)
def ctrace(name, rtn, *args):
    global ctrace_file
    if not do_ctrace:
        return
    print(f'{name}({", ".join([format_arg(i) for i in args])}) -> {format_arg(rtn)}')
    if file_output:
        #delete old ctrace file
        if ctrace_file is None:
            if os.path.exists('./ctrace.txt'):
                os.remove('./ctrace.txt')
            ctrace_file = open('./ctrace.txt', 'w')
        
        print(f'{name}({", ".join([format_arg(i) for i in args])}) -> {format_arg(rtn)}', file=ctrace_file, flush=True)

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
    ctrace('init', pdc_id, name)
    if pdc_id == 0:
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
    ctrace('close', err, pdc_id)
    if err != 0:
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

    def as_numpy_type(self):
        '''
        Returns the numpy type corresponding to this PDC type
        '''
        if self == Type.INT:
            return np.dtype('=i')
        elif self == Type.UINT:
            return np.uintc.newbyteorder('=')
        elif self == Type.FLOAT:
            return np.dtype('=f')
        elif self == Type.DOUBLE:
            return np.dtype('=d')
        elif self == Type.CHAR:
            return np.dtype('=c')
        elif self == Type.INT64:
            return np.dtype('=i8')
        elif self == Type.UINT64:
            return np.dtype('=u8')
        elif self == Type.INT16:
            return np.dtype('=h')
        elif self == Type.INT8:
            return np.dtype('=b')
        else:
            raise ValueError('Unknown PDC type')
        #TODO: add inverse operation

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

    tag_types = (tuple, str, int, float, bool, type(None))
    tag_types_union = Union[tuple, str, int, float, bool, type(None)]

    @classmethod
    def _encode(cls, obj:tag_types_union) -> bytes:
        if isinstance(obj, tuple):
            for i in obj:
                if not isinstance(i, cls.tag_types):
                    raise ValueError('tuples must contain only strings, ints, floats, and tuples')
            if len(obj) == 0:
                return b'()'
            elif len(obj) == 1:
                return b'(' + cls._encode(obj[0]) + b',)'
            else:
                return b'(' + b','.join([cls._encode(i) for i in obj]) + b')'
        elif isinstance(obj, str):
            return repr(obj).encode('utf-8')
        elif isinstance(obj, int):
            return str(obj).encode('utf-8')
        elif isinstance(obj, float):
            return str(obj).encode('utf-8')
        elif isinstance(obj, bool):
            return str(obj).encode('utf-8')
        elif obj is None:
            return b'None'
        else:
            raise TypeError(f'Unsupported type of tag: {type(obj)}')
    
    @staticmethod
    def _decode(data:bytes) -> tag_types_union:
        return ast.literal_eval(data.decode('utf-8'))
    
    @abstractmethod
    def set(self, key:bytes, value:bytes):
        pass
    
    @abstractmethod
    def get(self, key:bytes) -> bytes:
        pass
    
    @abstractmethod
    def delete(self, key:bytes):
        pass

    def __getitem__(self, name:str):
        checktype(name, 'tag name', str)
        return type(self)._decode(self.get(name.encode('utf-8')))
    
    def __setitem__(self, name:str, value:tag_types_union):
        checktype(name, 'tag name', str)
        self.set(name.encode('utf-8'), type(self)._encode(value))
    
    def __delitem__(self, name:str):
        checktype(name, 'tag name', str)
        self.delete(name.encode('utf-8'))

class ServerContext:
    '''
    A context manager that starts and stops a single PDC server instance on enter and exit
    This is intended for testing
    '''
    def __enter__(self):
        path = shutil.which('pdc_server.exe')
        print(path)
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

def test():
    return cpdc.test()