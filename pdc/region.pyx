from functools import singledispatchmethod
import builtins

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
    
    @__init__.register
    def _(self, slice:int):
        pass
    
    @__init__.register
    def _(self, slice:builtins.slice):
        pass
    
    @__init__.register
    def _(self, slice:tuple):
        pass
    
    def get(self) -> 'Object.TransferRequest':
        pass
    
    def set(self, data) -> 'Object.TransferRequest':
        pass

class _RegionFactory:
    def __getitem__(self, *slices) -> Region:
        return Region(*slices)

region = _RegionFactory()