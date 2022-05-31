cimport cpdc
from typing import Union
import atexit

class PDCError(Exception):
    pass

_is_open = False

def init(name:str = None):
    global pdc_id, _is_open
    if not name:
        name = "PDC"
    name_bytes = name.encode('utf-8')
    pdc_id = cpdc.PDCinit(name_bytes)
    if not pdc_id:
        raise PDCError('Could not initialize PDC')
    _is_open = True

def close():
    global _is_open
    if not _is_open:
        return
    err = cpdc.PDCclose(pdc_id)
    if err < 0:
        raise PDCError('Could not close PDC')
    _is_open = False

atexit.register(close)
