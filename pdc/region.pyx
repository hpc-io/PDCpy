from functools import singledispatchmethod
import builtins
from pdc.main cimport malloc_or_memerr
from .main import checktype, uint64, checkrange, PDCError, pdcid, ctrace, _free_from_int
from pdc.cpdc cimport uint64_t, pdcid_t
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Free as free
from typing import Tuple
import copy

#free region info created by _construct_region_info
cdef void free_region_info(pdc_region_info *region_info):
    free(region_info[0].size)
    free(region_info[0].offset)
    free(region_info)

cdef pdc_region_info *construct_region_info(region, dims):
    size_ptr, offset_ptr = region._get_sizes_offsets(dims)
    cdef uint64_t *size_arr = <uint64_t *> <size_t> size_ptr
    cdef uint64_t *offset_arr = <uint64_t *> <size_t> offset_ptr
    
    cdef pdc_region_info *region_info = <pdc_region_info *> malloc_or_memerr(sizeof(pdc_region_info))
    region_info[0].ndim = len(dims)
    region_info[0].offset = offset_arr
    region_info[0].size = size_arr        
    return region_info

class Region:
    '''
    | A region, which specifies the location of a 'block' of data.  
    | Regions are created by slicing the :class:`region` object.
    | Examples:
    | all data of an object: ``region[:]``
    | the first row of a 2 dimensional object, or the first element of a 1 dimensional object: ``region[0]``
    | the first 3 elements of a 1 dimensional object: ``region[:3]``
    | the next 3 elements of a 1 dimensional object: ``region[3:6]``
    | the last 6 columns of the first 2 rows of an object: ``region[:2, 6:]``
    |
    | The slices used to create a region object may not have step values. (``region[1:100:4]`` is invalid)
    '''
    
    @singledispatchmethod
    def __init__(self, slice):
        raise TypeError(f'invalid type of slice: {type(slice)}')
    
    @staticmethod
    def validate_slice(slice:slice):
        '''
        Validates a slice object.

        :meta private:
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
        self.slices = (builtins.slice(cslice, cslice+1),)
    
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
    
    def is_absolute(self):
        '''
        | A region is absolute if the region's slices have both start and stop values.
        | returns True if the region is absolute
        | Examples:
        | ``region[2:3, :9]`` is not absolute
        | ``region[2:3, 8]`` is absolute
        '''
        for s in self.slices:
            if s.start is None or s.stop is None:
                return False
        return True
    
    def get_absolute(self, dims):
        '''
        | Return a new absolute region, using the given dimensions to determine ommitted start and stop values.
        | Examples:
        | ``region[:].get_absolute((3, 4)) -> region[0:3, 0:4]``
        | ``region[:2, 6:].get_absolute((10, 10)) -> region[0:2, 6:10]``
        '''
        newslices = []
        
        for s, d in zip(self.slices, dims):
            start = s.start if s.start is not None else 0

            if s.stop is not None and s.stop > d:
                raise ValueError(f'slice stop value {s.stop} is greater than the dimension {d}')
            stop = s.stop if s.stop is not None else d
            newslices.append(builtins.slice(start, stop))
        
        while len(newslices) < len(dims):
            newslices.append(builtins.slice(0, dims[len(newslices)]))
        
        return Region(tuple(newslices))
    
    def _get_sizes_offsets(self, dims:Tuple[uint64]) -> Tuple[pdcid, Tuple[uint64, ...]]:
        #returns sizes pointer, offsets pointer
        if len(self.slices) > len(dims):
            raise ValueError('region has more dimensions than object')
        newslices = list(self.slices)
        while len(newslices) < len(dims):
            newslices.append(builtins.slice(None))
        
        cdef uint64_t start, stop
        cdef uint64_t *size_arr = <uint64_t *> malloc_or_memerr(sizeof(uint64_t) * len(dims))
        cdef uint64_t *offset_arr = <uint64_t *> malloc_or_memerr(sizeof(uint64_t) * len(dims))
        try:
            for s, d in zip(newslices, dims):
                if s.stop is not None and s.stop > d:
                    raise ValueError(f'slice stop value {s.stop} is greater than the dimension {d}')
            
            for s, d, i in zip(newslices, dims, range(len(dims))):
                start = s.start if s.start is not None else 0
                stop = s.stop if s.stop is not None else d
                size_arr[i] = stop - start
                offset_arr[i] = start
        except:
            free(size_arr)
            free(offset_arr)
            raise
        
        return (<size_t> size_arr, <size_t> offset_arr)
        
    def _construct_with(self, dims:Tuple[uint64]) -> Tuple[pdcid, Tuple[uint64, ...]]:
        '''
        Constructs a pdc region based on the provided dimensions of the object.
        '''
        size_ptr, offset_ptr = self._get_sizes_offsets(dims)
        cdef uint64_t *size_arr = <uint64_t *> <size_t> size_ptr
        cdef uint64_t *offset_arr = <uint64_t *> <size_t> offset_ptr
        cdef pdcid_t id
        try:
            id = cpdc.PDCregion_create(len(dims), offset_arr, size_arr)
            ctrace('region_create', id, len(dims), tuple(offset_arr[i] for i in range(len(dims))), tuple(size_arr[i] for i in range(len(dims))))
            if id == 0:
                raise PDCError('failed to create region')
            return id, tuple(size_arr[i] for i in range(len(dims)))
        finally:
            _free_from_int(size_ptr)
            _free_from_int(offset_ptr)
        
    def __eq__(self, other:object) -> bool:
        if not isinstance(other, Region):
            return False
        return self.slices == other.slices
    
    def __hash__(self) -> int:
        return hash(tuple(
            (s.start, s.stop) for s in self.slices
        ))
    
    def __repr__(self) -> str:
        return 'region[' + ', '.join(
            f'{"" if s.start is None else s.start}:{"" if s.stop is None else s.stop}' for s in self.slices
        ) + ']'

class _RegionFactory:
    def __getitem__(self, *slices) -> Region:
        return Region(*slices)

region = _RegionFactory()