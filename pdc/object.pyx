import builtins
import os
from functools import singledispatchmethod
from typing import Tuple, Optional, Iterable, Union
from enum import Enum
import numpy.typing as npt
from weakref import finalize
import ctypes

from pdc.main import uint32, uint64, Type, KVTags, _free_from_int, _get_pdcid, PDCError, PDCError, pdcid, checktype
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Malloc as malloc, PyMem_Free as free
from pdc.cpdc cimport uint32_t, uint64_t, pdc_access_t, pdcid_t, pdc_obj_prop, _pdc_obj_prop, pdc_obj_info, pdc_transfer_status_t, psize_t
from pdc.main cimport malloc_or_memerr
from . import container
from . import container as container_
from . import region
from .region import region, Region
from libc.string cimport strcpy
import numpy as np
from cpython.bytes cimport PyBytes_FromStringAndSize

cdef pdc_obj_prop prop_struct_from_prop(pdcid_t prop_id):
    cdef _pdc_obj_prop *private_struct = cpdc.PDC_obj_prop_get_info(prop_id)
    if private_struct == NULL:
        raise PDCError("could not get info for property")
    return (private_struct[0].obj_prop_pub)[0]

cdef pdc_obj_info get_obj_info(pdcid_t obj_id):
    cdef pdc_obj_info *private_struct = cpdc.PDCobj_get_info(obj_id)
    if private_struct == NULL:
        raise PDCError("could not get info for object")
    return private_struct[0]

class ObjectKVTags(KVTags):
    def __init__(self, obj):
        self.obj = obj
    
    def delete(self, name:bytes):
        if cpdc.PDCobj_del_tag(self.obj._id, name) != 0:
            raise PDCError("tag does not exist or could not delete tag")
    
    def get(self, name:bytes):
        cdef void* value_out
        cdef psize_t size_out
        if cpdc.PDCobj_get_tag(self.obj._id, name, &value_out, &size_out) != 0:
            raise PDCError("tag does not exist or could not get tag")
        rtn = PyBytes_FromStringAndSize(<char *> value_out, size_out)
        return rtn
    
    def set(self, name:bytes, value:bytes):
        if cpdc.PDCobj_put_tag(self.obj._id, name, <char *> value, len(value)) != 0:
            raise PDCError("could not set tag")

class Object:
    '''
    A PDC object
    '''

    class Properties:
        '''
        Contains most of the metadata associated with an object.
        This is an inner class of Object
        '''
        _id:pdcid

        _dims_ptr:uint64

        def __init__(self, dims:Union[Tuple[uint32, ...], uint32], type:Type=Type.INT, uint32_t time_step:uint32=0, user_id:Optional[uint32]=None, str app_name:str='', *, _fromid:Optional[pdcid]=None):
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
            cdef pdcid_t id = cpdc.PDCprop_create(cpdc.pdc_prop_type_t.PDC_OBJ_CREATE, _get_pdcid())
            if id == 0:
                raise PDCError('Failed to create object')
            self._id = id
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
            if cpdc.PDCprop_close(id) != 0:
                raise PDCError('Failed to close object')
        
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

            try:
                for i in range(length):
                    dims_ptr[i] = dims[i]
                
                if cpdc.PDCprop_set_obj_dims(self._id, length, dims_ptr) != 0:
                    raise PDCError('Failed to set object dimensions')
            finally:
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
            if cpdc.PDCprop_set_obj_type(self._id, type.value) != 0:
                raise PDCError('Failed to set object type')
        
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
            if cpdc.PDCprop_set_obj_time_step(self._id, time_step) != 0:
                raise PDCError('Failed to set object time step')
        
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
            
            rtn = cpdc.PDCprop_set_obj_app_name(self._id, name.encode('utf-8'))
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
        
        def __eq__(self, other) -> bool:
            if not isinstance(other, type(self)):
                return False
            return self._id == other._id or (self.dims == other.dims and self.type == other.type and self.time_step == other.time_step and self.user_id == other.user_id and self.app_name == other.app_name)
        
        def __hash__(self) -> int:
            return hash((self.dims, self.type, self.time_step, self.user_id, self.app_name))
    
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

        def wait_for_result(self):
            '''
            Wait for the result of the transfer request
            '''
            if cpdc.PDCregion_transfer_wait(self._id) != 0:
                raise PDCError('Failed to wait for transfer request')
            return self.result

        @property
        def done(self) -> bool:
            '''
            True if this transfer request is completed
            '''
            cdef pdc_transfer_status_t out_status
            cpdc.PDCregion_transfer_status(self._id, &out_status)
            if out_status == pdc_transfer_status_t.PDC_TRANSFER_STATUS_NOT_FOUND:
                raise PDCError('could not get transfer request status: transfer request not found')
            elif out_status == pdc_transfer_status_t.PDC_TRANSFER_STATUS_COMPLETE:
                return True
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
            if self.type == type(self).RequestType.SET or not self.done:
                return None
            return self._out
        
        def __init__(self, remoteRegion:Region, object:'Object', request_type:RequestType, data=None):
            #TODO: make this hold a reference to the object
            '''
            __init__(*args)
            '''
            checktype(remoteRegion, 'remote region', Region)
            checktype(object, 'object', Object)
            checktype(request_type, 'request type', type(self).RequestType)

            region_id, sizes = remoteRegion._construct_with(object.dims)
            cdef pdcid_t local_region_id = 0

            try:
                _id, _ = region[:]._construct_with(sizes)
                if _id == 0:
                    raise PDCError('failed to construct region')
                local_region_id = _id

                if request_type == type(self).RequestType.SET:
                    np_data = np.require(data, requirements=['C', 'A'], dtype=object.type.as_numpy_type())

                    if np_data.ndim > len(sizes):
                        raise ValueError(f'data has {np_data.ndim} dimensions, but {len(sizes)} are allowed')
                    else:
                        diff = len(sizes) - np_data.ndim
                        new_shape = (1,) * diff + np_data.shape
                        if sizes != new_shape:
                            raise ValueError(f'data shape {np_data.shape} does not match region shape {sizes}')
                        np_data.reshape(sizes)
                    
                    transfer_id = cpdc.PDCregion_transfer_create(<void *> <size_t> np_data.ctypes.data, type(self).RequestType.SET.value, object._id, local_region_id, region_id)
                    if transfer_id == 0:
                        raise PDCError('failed to create transfer')
                    self._id = transfer_id
                    self._out = None
                    self._local_id = local_region_id
                else:
                    out = np.empty(sizes, dtype=object.type.as_numpy_type())
                    transfer_id = cpdc.PDCregion_transfer_create(<void *> <size_t> out.ctypes.data, type(self).RequestType.GET.value, object._id, local_region_id, region_id)
                    if transfer_id == 0:
                        raise PDCError('failed to create transfer')
                    self._id = transfer_id
                    self._out = out
                    self._local_id = local_region_id
            except:
                rtn = cpdc.PDCregion_close(region_id)
                rtn2 = 0
                if local_region_id != 0:
                    rtn2 = cpdc.PDCregion_close(local_region_id)
                if rtn != 0 or rtn2 != 0:
                    raise PDCError('Failed to create region')
                raise
            
            finalize(self, type(self)._finalize, self._id, self._local_id)
            if cpdc.PDCregion_transfer_start(self._id) != 0:
                raise PDCError('failed to start transfer')
        
        @staticmethod
        def _finalize(id, local_id):
            rtn = cpdc.PDCregion_close(local_id)
            rtn2 = cpdc.PDCregion_close(id)
            if rtn != 0 or rtn2 != 0:
                raise PDCError('Failed to close region')
        
    def __init__(self, name:str, properties:Properties, container:container.Container, *, _fromid:Optional[pdcid] = None):
        '''
        __init__(self, name:str, properties:Properties, container:container.Container)
        Create a new object.  To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param ObjectProperties properties: An ObjectProperties describing the properties of the object.
        :param Container container: the container this object should be placed in.
        '''
        checktype(name, 'name', str)
        checktype(properties, 'properties', type(self).Properties)
        checktype(container, 'container', container_.Container)
        
        if _fromid is not None:
            self._id = _fromid
            return
        cdef pdcid_t id = cpdc.PDCobj_create(container._id, name.encode('utf-8'), properties._id)
        if id == 0:
            raise PDCError('failed to create object')
        self._id = id
    
    #pdc_obj_prop.obj_prop_id is not used, so this is not implementable:
    #def get_properties(self) -> 'Properties':
    #    '''
    #    Get a copy of the properties of this object.  read-only
    #    '''
    #    cdef pdcid_t prop_id = (get_obj_info(self._id).obj_pt)[0].obj_prop_id
    #    raise PDCError(str(prop_id))
    #    return type(self).Properties(None, _fromid=prop_id).copy()
    
    @property
    def dims(self) -> Tuple[uint64, ...]:
        '''
        The dimensions of this object.  read-only
        Equivalent to ``obj.get_properties().dims``
        '''
        cdef pdc_obj_prop obj_prop = (get_obj_info(self._id).obj_pt)[0]
        cdef uint64_t ndims = obj_prop.ndim
        cdef uint64_t *dims = obj_prop.dims
        return tuple(dims[i] for i in range(ndims))
    
    @property
    def type(self) -> Type:
        '''
        The type of this object.  read-only
        Equivalent to ``obj.get_properties().type``
        '''
        typenum = (get_obj_info(self._id).obj_pt)[0].type
        try:
            return Type(typenum)
        except ValueError:
            raise PDCError(f"unimplemented type number: {typenum}")
    
    @property
    def name(self) -> str:
        '''
        The name of this object. read-only
        '''
        return get_obj_info(self._id).name.decode('utf-8')
    
    @property
    def data(self) -> 'DataQueryComponent':
        '''
        An object used to build queries.
        ex. ``query = my_object.data > 1``
        '''
        pass

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
        if id == 0:
            raise PDCError('object not found or failed to open object')
        return Object(_fromid=id)
    
    @property
    def tags(self) -> KVTags:
        return ObjectKVTags(self)
    
    def get_data(self, region:'Region'=region[:]) -> TransferRequest:
        '''
        Request a region of data from an object

        :param Region region: the region of data to get.  Defaults to the entire object.
        :return: A transfer request representing this request
        :rtype: TransferRequest
        '''
        return type(self).TransferRequest(
            region,
            self,
            type(self).TransferRequest.RequestType.GET
        )
    
    def set_data(self, data:npt.ArrayLike, region:'Region'=region[:]) -> TransferRequest:
        '''
        Request a region of data from an object to be set to a new value

        :param Region region: the region of data to set. Defaults to the entire object.
        :param data: The data to set the region to.
        :return: A TransferRequest representing this request
        :rtype: TransferRequest
        '''
        return type(self).TransferRequest(
            region,
            self,
            type(self).TransferRequest.RequestType.SET,
            data
        )
    
    def delete(self):
        '''
        Delete this Object.
        Do not access any methods or properties of this object after calling.
        '''
        if cpdc.PDCobj_del(self._id) != 0:
            raise PDCError('failed to delete object')
        #leave self._id as is, because we still need to finalize
    