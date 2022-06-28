import builtins
import os
from functools import singledispatchmethod
from typing import Tuple, Optional, Iterable, Union
from enum import Enum
import numpy.typing as npt
from weakref import finalize

from pdc.main import uint32, uint64, Type, KVTags, _free_from_int, _get_pdcid, PDCError, PDCError, pdcid, checktype
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
from pdc.cpdc cimport uint32_t, uint64_t, pdc_access_t, pdcid_t, pdc_obj_prop, _pdc_obj_prop
from pdc.main cimport malloc_or_memerr
from . import container
from . import region
from libc.string cimport strcpy

cdef pdc_obj_prop prop_struct_from_prop(pdcid_t prop_id):
    return ((cpdc.PDC_obj_prop_get_info(prop_id))[0].obj_prop_pub)[0]

class Object:
    '''
    A PDC object
    '''

    def get_properties(self) -> 'Properties':
        '''
        Get a copy of the properties of this object.  read-only
        '''
        pass
    
    @property
    def dims(self) -> Tuple[uint32, ...]:
        '''
        The dimensions of this object.  read-only
        Equivalent to ``obj.get_properties().dims``
        '''
        pass
    
    @property
    def type(self) -> Type:
        '''
        The type of this object.  read-only
        Equivalent to ``obj.get_properties().type``
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

        def __init__(self, dims:Union[Tuple[uint32, ...], uint32], type:Type=Type.INT, uint32_t time_step:uint32=0, user_id:Optional[uint32]=None, str app_name:str='', _fromid:Optional[pdcid]=None):
            '''
            __init__(self, dims:Union[Tuple[uint32, ...], uint32], type:Type=Type.INT, uint32_t time_step:uint32=0, user_id:Optional[uint32]=None, str app_name:str='')

            :param dims: A tuple containing dimensions of the object, or a single integer for 1-D objects.  For example, (10, 3) means 10 rows and 3 columns.  1 <= len(dims) <= 2^31-1 
            :type dims: Tuple[int]
            :param Type type: the data type.  Defaults to INT
            :param uint32 time_step: For applications that involve data along a time axis, this represents the point in time of the data.  Defaults to 0.
            :param uint32 user_id: the id of the user.  defaults to os.getuid()
            :param str app_name: the name of the application.  Defaults to an empty string.
            '''

            global pdc_id
            self._id = cpdc.PDCprop_create(cpdc.pdc_prop_type_t.PDC_OBJ_CREATE, _get_pdcid())
            self._finalizer = finalize(self, builtins.type(self)._finalize, self._id)
            if _fromid is not None:
                self._id = _fromid
                return

            if user_id is None:
                user_id = os.getuid()
            
            self.dims = dims
            self.app_name = app_name
            self.type = type
            self.time_step = time_step
            self.user_id = user_id
        
        @staticmethod
        def _finalize(id):
            cpdc.PDCprop_close(id)            
        
        @property
        def dims(self) -> Tuple[int, ...]:
            '''
            The dimensions of this object as a tuple.
            '''
            cdef pdc_obj_prop prop_struct = prop_struct_from_prop(self._id)
            cdef uint64_t *dims_array = prop_struct.dims
            cdef size_t dims_len = prop_struct.ndim
            rtn = []
            for i in range(dims_len):
                rtn.append(dims_array[i])
            return tuple(rtn)
        
        @dims.setter
        def dims(self, dims:Union[Tuple[uint32, ...], uint32]):
            if isinstance(dims, int):
                dims = (dims,)
            checktype(dims, 'dims', tuple)
            if not 1 <= len(dims) <= 2**31-1:
                raise ValueError('dims must be at most 2^31-1 elements long')
            for d in dims:
                checktype(d, 'dims', int)
                if d < 0:
                    raise ValueError('dims must be non-negative')

            cdef uint32_t length = len(dims)

            cdef uint64_t *dims_ptr = <uint64_t*> malloc_or_memerr(length * sizeof(uint64_t))

            for i in range(length):
                dims_ptr[i] = dims[i]
            
            cpdc.PDCprop_set_obj_dims(self._id, length, dims_ptr)

            free(dims_ptr)

        @property
        def type(self) -> Type:
            '''
            The data type of this object.
            '''
            cdef pdc_obj_prop prop_struct = prop_struct_from_prop(self._id)
            if prop_struct.type == -1:
                raise PDCError('property type not set')
            try:
                return Type(prop_struct.type)
            except ValueError:
                raise PDCError(f'unimplemented type: {prop_struct.type}')
        
        @type.setter
        def type(self, type:Type):
            checktype(type, 'type', Type)
            cpdc.PDCprop_set_obj_type(self._id, type.value)
        
        @property
        def time_step(self) -> uint32:
            '''
            The time step of this object.
            For applications that involve data along a time axis, this represents the point in time of the data.
            '''
            cdef _pdc_obj_prop prop_struct = (cpdc.PDC_obj_prop_get_info(self._id))[0]
            return prop_struct.time_step
        
        @time_step.setter
        def time_step(self, time_step:uint32):
            checktype(time_step, 'time step', int)
            cpdc.PDCprop_set_obj_time_step(self._id, time_step)
        
        @property
        def user_id(self) -> uint32:
            '''
            the id of the user.
            '''
            cdef _pdc_obj_prop prop_struct = (cpdc.PDC_obj_prop_get_info(self._id))[0]
            return prop_struct.user_id
        
        @user_id.setter
        def user_id(self, id:uint32):
            checktype(id, 'user_id', int)
            
            rtn = cpdc.PDCprop_set_obj_user_id(self._id, id)
            if rtn != 0:
                raise PDCError('failed to set user_id')
        
        @property
        def app_name(self) -> str:
            '''
            The name of the application
            '''
            cdef _pdc_obj_prop prop_struct = (cpdc.PDC_obj_prop_get_info(self._id))[0]
            return prop_struct.app_name.decode('utf-8')
        
        @app_name.setter
        def app_name(self, str name:str):
            checktype(name, 'app name', str)
            cdef char *app_ptr = <char*> malloc_or_memerr((len(name.encode('utf-8'))+1) * sizeof(char))
            strcpy(app_ptr, name.encode('utf-8'))
            
            rtn = cpdc.PDCprop_set_obj_app_name(self._id, app_ptr)
            free(app_ptr)
            if rtn != 0:
                raise PDCError('failed to set app name')
        
        def copy(self) -> 'Properties':
            '''
            Copy this properties object

            :return: A copy of this object
            :rtype: Properties 
            '''
            return type(self)(
                dims=self.dims,
                type=self.type,
                time_step=self.time_step,
                user_id=self.user_id,
                app_name=self.app_name
            )
    
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
    
    def __init__(self, name:str, properties:Properties, container:container.Container, _fromid:Optional[pdcid] = None):
        '''
        __init__(self, name:str, properties:Properties, container:container.Container)
        Create a new object.  To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param ObjectProperties properties: An ObjectProperties describing the properties of the object
        :param Container container: the container this object should be placed in.
        '''
        checktype(name, 'name', str)
        checktype(properties, 'properties', type(self).Properties)
        checktype(container, 'container', container.Container)
        
        if _fromid is not None:
            self._id = _fromid
            return
        cdef pdcid_t id = cpdc.PDCobj_create(name.encode('utf-8'), properties._id, container._id)
        if id == -1:
            raise PDCError('failed to create object')
        self._id = id

    @staticmethod
    def get(name:str) -> 'Object':
        '''
        Get an existing object by name

        If you have created multiple objects with the same name, this will return the one with time_step=0
        If there are multiple objects with the same name and time_step, the tie is broken arbitrarily
        
        :param str name: the name of the object
        '''
        checktype(name, 'name', str)
        cdef pdcid_t id = cpdc.PDCobj_open(name.encode('utf-8'), _get_pdcid())
        if id == -1:
            raise PDCError('object not found or failed to open object')
        return Object(_fromid=id)
    
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
        cpdc.PDCobj_del(self._id)
        #leave self._id as is, because we still need to finalize
    