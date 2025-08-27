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
import numpy.typing as npt
import pickle # this is available in python 3.8+, otherwise you need to pip install pickle

try:
    from mpi4py import MPI
except ImportError:
    MPI = None

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
do_ctrace = False
do_ctrace_print = False
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
    
    if do_ctrace_print:
        print(f'{name}({", ".join([format_arg(i) for i in args])}) -> {format_arg(rtn)}')
    
    if MPI is None:
        rank = 0
    else:
        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
    
    #delete old ctrace file
    try:
        if ctrace_file is None:
            filename = f'./ctrace_{rank}.txt'
            if os.path.exists(filename):
                os.remove(filename)
                ctrace_file = open(filename, 'w')
        print(f'{name}({", ".join([format_arg(i) for i in args])}) -> {format_arg(rtn)}', file=ctrace_file, flush=True)
    except Exception as e:
        print(f'Error opening ctrace file: {e}')
    

def enable_ctrace():
    global do_ctrace
    do_ctrace = True

def disable_ctrace():
    global do_ctrace
    do_ctrace = False

class PDCError(Exception):
    '''
    A general error type that indicates an error from the underlying c pdc api.
    Don't count on getting this error most of the time.  Usually, the server/client segfaults instead.
    '''
    pass

_is_open = False

def _get_pdcid() -> pdcid:
    global pdc_id
    return pdc_id

def init(name:str="PDC"):
    '''
    Initialize PDC.
    This call will block and eventually terminate the program if the PDC server is not running in the same directory as the program.
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
    #sraise Exception('PDC is already closed')
    ctrace('close', '?', pdc_id)
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
    True if :func:`init` has been called, False otherwise
    '''
    return _is_open

class Type(Enum):
    '''
    All of the data types that PDC objects support
    '''

    INT32    = pdc_var_type_t.PDC_INT
    FLOAT    = pdc_var_type_t.PDC_FLOAT
    DOUBLE   = pdc_var_type_t.PDC_DOUBLE
    #removed for being identical to INT8:
    #CHAR     = pdc_var_type_t.PDC_CHAR
    UINT32   = pdc_var_type_t.PDC_UINT
    INT64    = pdc_var_type_t.PDC_INT64
    UINT64   = pdc_var_type_t.PDC_UINT64
    INT16    = pdc_var_type_t.PDC_INT16
    INT8     = pdc_var_type_t.PDC_INT8
    UINT8    = pdc_var_type_t.PDC_UINT8

    def as_numpy_type(self):
        '''
        Returns the numpy type corresponding to this PDC type
        '''
        if self == Type.INT32:
            return np.dtype('=i4')
        elif self == Type.UINT32:
            return np.dtype('=u4')
        elif self == Type.FLOAT:
            return np.dtype('=f')
        elif self == Type.DOUBLE:
            return np.dtype('=d')
        elif self == Type.INT64:
            return np.dtype('=i8')
        elif self == Type.UINT64:
            return np.dtype('=u8')
        elif self == Type.INT16:
            return np.dtype('=h')
        elif self == Type.INT8:
            return np.dtype('=b')
        elif self == Type.UINT8:
            return np.dtype('=B')
        else:
            raise ValueError('Unknown PDC type')
    
    @staticmethod
    def from_numpy_type(dtype):
        '''
        Returns the PDC type corresponding to this numpy type

        :param dtype: The numpy type
        :raises ValueError: If the numpy type has no corresponding PDC type
        '''
        old_dtype = dtype
        dtype = np.dtype(dtype)
        if dtype == np.dtype('=i4'):
            return Type.INT32
        elif dtype == np.dtype('=u4'):
            return Type.UINT32
        elif dtype == np.dtype('=f'):
            return Type.FLOAT
        elif dtype == np.dtype('=d'):
            return Type.DOUBLE
        elif dtype == np.dtype('=c'):
            return Type.INT8
        elif dtype == np.dtype('=i8'):
            return Type.INT64
        elif dtype == np.dtype('=u8'):
            return Type.UINT64
        elif dtype == np.dtype('=h'):
            return Type.INT16
        elif dtype == np.dtype('=b'):
            return Type.INT8
        elif dtype == np.dtype('=B'):
            return Type.UINT8
        else:
            raise ValueError(f'Unsupported numpy type: {old_dtype}')
    
    '''
    currently unused
    def validate(self, value:object):
        cdef int int_
        cdef unsigned int uint_
        cdef float float_
        cdef double double_
        cdef char char_
        cdef int64_t int64_
        cdef uint64_t uint64_ 
        cdef int16_t int16_
        cdef int8_t int8_
        if self in (Type.FLOAT, Type.DOUBLE):
            checktype(value, 'value', float)
        else:
            checktype(value, 'value', float)
        try:
            if self == Type.INT:
                int_ = value
            elif self == Type.UINT:
                uint_ = value
            elif self == Type.FLOAT:
                float_ = value
            elif self == Type.DOUBLE:
                double_ = value
            elif self == Type.CHAR:
                char_ = value
            elif self == Type.INT64:
                int64_ = value
            elif self == Type.UINT64:
                uint64_ = value
            elif self == Type.INT16:
                int16_ = value
            elif self == Type.INT8:
                int8_ = value
            else:
                raise ValueError(f'Unknown PDC type: {self.name}')
        except OverflowError:
            raise OverflowError(f'value {value} is not within the acceptable range for {self.name}') from None
    '''

class KVTags(ABC):
    '''
    An object used to manipulate object and container tags.
    Supports the following operations:

    =================== ==============================
    operation           effect
    =================== ==============================
    ``value = tags[x]`` get the value of the tag ``x``
    ``tags[x] = value`` set the value of the tag ``x``
    ``del tags[x]``     delete the tag ``x``
    =================== ==============================
    '''
    primitive_types = (bytes, str, int, float, bool, type(None))
    tag_types = (tuple, list, dict, bytes, str, int, float, bool, type(None))
    tag_types_union = Union[tuple, list, dict, bytes, str, int, float, bool, type(None)]

    @classmethod
    def _encode(cls, obj:tag_types_union) -> bytes:
        if isinstance(obj, tuple) and not obj:
            return b'()'
        try:
            if isinstance(obj, tuple):
                if not obj:
                    return b'()'
                for i in obj:
                    if not isinstance(i, cls.primitive_types):
                        raise ValueError('tuples must contain only strings, ints, floats, bools, bytes, fallback to pickle.dumps() -> bytes')
                if len(obj) == 1:
                    return b'(' + cls._encode(obj[0]) + b',)'
                else:
                    return b'(' + b','.join([cls._encode(i) for i in obj]) + b')'
            elif isinstance(obj, list):
                if not obj:
                    return b'[]'
                for i in obj:
                    if not isinstance(i, cls.primitive_types):
                        raise ValueError('lists must contain only strings, ints, floats, bools, bytes, fallback to pickle.dumps() -> bytes')
                if len(obj) == 1:
                    return b'[' + cls._encode(obj[0]) + b']'
                else:
                    return b'[' + b','.join([cls._encode(i) for i in obj]) + b']'
            elif isinstance(obj, dict):
                for k, v in obj.items():
                    if not isinstance(k, str):
                        raise ValueError('dict keys must be strings')
                    if not isinstance(v, cls.primitive_types):
                        raise ValueError('dict values must be strings, ints, floats, bools, bytes, fallback to pickle.dumps() -> bytes')
                return b'{' + b','.join([cls._encode(k) + b': ' + cls._encode(v) for k, v in obj.items()]) + b'}'
            elif isinstance(obj, bytes):
                return obj
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
                raise ValueError(f'Unsupported type of tag: {type(obj)}, fallback to pickle.dumps() -> bytes')
        except ValueError as e:
            return pickle.dumps(obj)
    
    @staticmethod
    def _decode(data:bytes) -> tag_types_union:
        # if the data is a pickle, use pickle.loads()
        if data.startswith(b'\x80'):
            return pickle.loads(data)
        # otherwise, try to eval the string
        return ast.literal_eval(data.decode('utf-8'))
    
    @abstractmethod
    def set(self, key:bytes, value:bytes):
        '''
        :meta private:
        '''
        pass
    
    @abstractmethod
    def get(self, key:bytes) -> bytes:
        '''
        :meta private:
        '''
        pass
    
    @abstractmethod
    def delete(self, key:bytes):
        '''
        :meta private:
        '''
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
    A context manager that starts and stops a single PDC server instance on enter and exit.
    This is intended for testing.
    
    Usage::
    
        with pdc.ServerContext():
            pdc.init()
            ...
    
    :raises FileNotFoundError: if pdc_server is not on PATH
    '''
    def __enter__(self):
        path = shutil.which('pdc_server')
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

def checktype(value, name, *expected):
    for et in expected:
        if isinstance(value, et):
            return
    raise TypeError(f'invalid type of {name}: {type(value)}, expected : one of {[x.__name__ for x in expected]}')

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
