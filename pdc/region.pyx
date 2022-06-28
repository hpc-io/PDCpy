from functools import singledispatchmethod
import builtins
from pdc.main cimport malloc_or_memerr
from .main import checktype, uint64, checkrange, PDCError, pdcid
from pdc.cpdc cimport uint64_t, pdcid_t
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Free as free
from typing import Tuple

class Region:
    '''
    A region, which specifies the location of a 'block' of data.  
    For example, a region can represent columns 2-8 of rows 1-3 of an object with 2 dimensionsf
    Regions are created by slicing the :class:`region` object.
    The previous region example can be created with ``pdc.region[1:4, 2:9]``
    '''
    
    @singledispatchmethod
    def __init__(self, slice):
        raise TypeError(f'invalid type of slice: {type(slice)}')
    
    @staticmethod
    def validate_slice(slice:slice):
        '''
        Validates a slice object.
        '''
        checktype(slice, 'slice', builtins.slice)
        if slice.start is not None:
            checktype(slice.start, 'start value', int)
            checkrange(slice.start, 'start value', 'uint64')
        if slice.stop is not None:
            checktype(slice.stop, 'stop value', int)
            checkrange(slice.stop, 'stop value', 'uint64')
        if slice.step is not None and slice.step != 1:
            raise ValueError('slice step values are not supported')
        if slice.start is not None and slice.stop is not None and slice.start >= slice.stop:
            raise ValueError('start value cannot be greater or equal to than stop value')

    @__init__.register
    def _(self, slice:int):
        cdef uint64_t cslice = slice
        self.slices = builtins.slice(cslice, cslice+1)
    
    @__init__.register
    def _(self, slice:builtins.slice):
        Region.validate_slice(slice)
        self.slices = (slice,)
    
    @__init__.register
    def _(self, slice:tuple):
        checktype(slice, 'slice', tuple)
        if len(slice) == 0:
            raise ValueError('region must have at least one dimension')
        
        newslices = []
        for s in slice:
            if isinstance(s, builtins.slice):
                Region.validate_slice(s)
                newslices.append(s)
            else:
                checktype(s, 'slice', int)
                checkrange(s, 'slice', 'uint64')
                newslices.append(builtins.slice(s, s+1))
        
        self.slices = tuple(newslices)
    
    def _construct_with(self, dims:Tuple[uint64]) -> pdcid:
        '''
        Constructs a pdc region based on the provided dimensions of the object.
        '''
        if len(self.slices) > len(dims):
            raise ValueError('region has more dimensions than object')
        newslices = list(self.slices)
        while len(newslices) < len(dims):
            newslices.append(builtins.slice(None))

        cdef uint64_t *size_arr = <uint64_t *> malloc_or_memerr(sizeof(uint64_t) * len(dims))
        cdef uint64_t *offset_arr = <uint64_t *> malloc_or_memerr(sizeof(uint64_t) * len(dims))

        cdef uint64_t start, stop
        cdef pdcid_t id
        try:
            for s, d in zip(self.slices, dims):
                if s.stop is not None and s.stop > d:
                    raise ValueError(f'slice stop value {s.stop} is greater than the dimension {d}')
            
            for s, d in zip(self.slices, dims):
                start = s.start if s.start is not None else 0
                stop = s.stop if s.stop is not None else d
                size_arr[slice.start] = stop - start
                offset_arr[slice.start] = start
            
            id = cpdc.PDCregion_create(len(dims), offset_arr, size_arr)
            if id == 0:
                raise PDCError('failed to create region')
            return id
        finally:
            free(size_arr)
            free(offset_arr)

class _RegionFactory:
    def __getitem__(self, *slices) -> Region:
        return Region(*slices)

region = _RegionFactory()