cimport cpdc
from cpdc cimport uint32_t, pdc_var_type_t
from typing import Union
import atexit
from typing import Iterable
from enum import IntEnum

class PDCError(Exception):
    pass

_is_open = False

def _init(name:str):
    global pdc_id, _is_open
    name_bytes = name.encode('utf-8')
    pdc_id = cpdc.PDCinit(name_bytes)
    if not pdc_id:
        raise PDCError('Could not initialize PDC')
    _is_open = True

_init("PDC")

def _close():
    global _is_open
    if not _is_open:
        return
    err = cpdc.PDCclose(pdc_id)
    if err < 0:
        raise PDCError('Could not close PDC')
    _is_open = False

atexit.register(_close)

class Types(IntEnum):
    '''
    All of the data types that objects support  
    '''
    INT      = 0
    FLOAT    = 1
    DOUBLE   = 2
    CHAR     = 3
    COMPOUND = 4
    ENUM     = 5
    ARRAY    = 6
    UINT     = 7
    INT64    = 8
    UINT64   = 9
    INT16    = 10
    INT8     = 11

class ObjectProperties:
    def __init__(self, properties:ObjectProperties=None, *, uint32_t user_id=0, data_loc:str='', app_name:str='', uint32_t time_step=0, dims:Sequence[int]=None, pdc_var_type_t type=Types.INT):
        pass


class Object:
    '''
    
    '''
    pass