import builtins
import os
from functools import singledispatchmethod
from typing import Tuple, Optional, Iterable, Union
from enum import Enum
import numpy.typing as npt
from weakref import finalize

from pdc.main import uint32, uint64, Type, KVTags, _free_from_int
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
from pdc.cpdc cimport uint32_t, uint64_t, pdc_access_t
from pdc.main cimport malloc_or_memerr
from . import container
from . import region

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
    
    @property
    def data(self) -> 'DataQueryComponent':
        '''
        An object used to build queries.
        ex. ``query = my_object.data > 1``
        '''
        pass

    class Properties:
        '''
        Contains most of the metadata associated with an object.
        This is an inner class of Object
        '''
        _id:pdcid

        _dims_ptr:uint64

        def __init__(self, dims:Union[Tuple[int], int], type:Type=Type.INT, uint32_t time_step:uint32=0, user_id:Optional[uint32]=None, str app_name:str=''):
            '''
            :param dims: A tuple containing dimensions of the object, or a single integer for 1-D objects.  For example, (10, 3) means 10 rows and 3 columns.  1 <= len(dims) <= 2^31-1 
            :type dims: Tuple[int]
            :param Type type: the data type.  Defaults to INT
            :param uint32 time_step: For applications that involve data along a time axis, this represents the point in time of the data.  Defaults to 0.
            :param uint32 user_id: the id of the user.  defaults to os.getuid()
            :param str app_name: the name of the application.  Defaults to an empty string.
            '''
            if user_id is None:
                user_id = os.getuid()
            
            global pdc_id
            self._id = cpdc.PDCprop_create(cpdc.pdc_prop_type_t.PDC_OBJ_CREATE, pdc_id)        
            self.app_name = app_name
            self.type = type
            self.time_step = time_step
            self.user_id = user_id
            self._finalizer = None
        
        @staticmethod
        def _finalize(id, ptrs):
            for p in ptrs:
                _free_from_int(p)

        def _reregister_finalizer(self):
            if self._finalizer:
                self._finalizer.detach()
            finalize(self, type(self)._finalize, self._id, self._dims_ptr)
        
        @property
        def dims(self) -> Tuple[int]:
            pass
        
        @dims.setter
        def dims(self, dims:Union[Tuple[int], int]):
            if isinstance(dims, int):
                dims = (dims,)
            if not isinstance(dims, tuple):
                raise TypeError(f"invalid type of dims: {type(dims)}.  expected tuple")
            if not 1 <= len(dims) <= 2**31-1:
                raise ValueError('dims must be at most 2^31-1 elements long')
            
            cdef uint32_t length = len(dims)

            cdef uint64_t *dims_ptr = <uint64_t*> malloc_or_memerr(length * sizeof(uint64_t))
            self._dims_ptr = <uint64_t> dims_ptr
            self._reregister_finalizer()

            for i in range(length):
                dims_ptr[i] = dims[i]
            
            cpdc.PDCprop_set_obj_dims(self._id, length, dims_ptr)

            self._dims = dims
        
        @property
        def type(self) -> Type:
            pass
        
        @type.setter
        def type(self, type:Type):
            if not isinstance(type, Type):
                raise TypeError(f"invalid type of type: {builtins.type(type)}.  Expected Type")
            
            cpdc.PDCprop_set_obj_type(self._id, type.value)
        
        @property
        def time_step(self) -> uint32:
            pass
        
        @time_step.setter
        def time_step(self, uint32_t time_step:uint32):
            cdef uint32_t time_step_c = time_step
            cpdc.PDCprop_set_obj_time_step(self._id, time_step_c)
        
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
            Copy this properties object

            :return: A copy of this object
            :rtype: Properties 
            '''
            pass
    
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
            result(self) -> Optional[npt.NDArray]
            If the request is done and the request type is RequestType.GET, this is a numpy array containing the requested data.
            '''
            return None
    
    @singledispatchmethod
    def __init__(self, name, *args):
        '''
        Create a new object.  To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param Object.Properties properties: An ObjectProperties describing the properties of the object
        :param Container container: the container this object should be placed in.
        '''
        raise TypeError(f'Invalid type of name: {type(name)}')

    @__init__.register
    def _(self, name:str, properties:Properties, container:container.Container):
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
        
        :param str name: the name of the object
        '''
        pass
    
    @property
    def tags(self) -> KVTags:
        '''
        Get the tags of this Object.  See :class:`KVTags` for more info
        '''
        pass
    
    def get_data(self, region:'Region'=region.region[:]) -> TransferRequest:
        '''
        Request a region of data from an object

        :param Region region: the region of data to get.  Defaults to the entire object.
        :return: A transfer request representing this request
        :rtype: TransferRequest
        '''
        pass
    
    def set_data(self, data:npt.ArrayLike, region:'Region'=region.region[:]) -> TransferRequest:
        '''
        Request a region of data from an object to be set to a new value

        :param Region region: the region of data to set. Defaults to the entire object.
        :param data: The data to set the region to.
        :return: A TransferRequest representing this request
        :rtype: TransferRequest
        '''
        pass
    
    def delete(self):
        '''
        Delete this Object.
        Do not access any methods or properties of this object after calling.
        '''
        pass