from enum import Enum
from typing import Iterable, Optional, Sequence, Union
from weakref import finalize, WeakValueDictionary
import numpy as np
import numpy.typing as npt

from .main import KVTags, checktype, _get_pdcid, PDCError, ctrace, Type
from pdc.cpdc cimport pdc_lifetime_t, pdc_prop_type_t, pdcid_t, _pdc_cont_info, psize_t, uint64_t, obj_handle, pdc_obj_info, cont_handle, pdc_cont_info
from pdc.main cimport malloc_or_memerr
import pdc
cimport pdc.cpdc as cpdc
from cpython.mem cimport PyMem_Free as free
from cpython.bytes cimport PyBytes_FromStringAndSize

cdef _pdc_cont_info *get_info_struct(pdcid_t id):
    cdef _pdc_cont_info *info = cpdc.PDC_cont_get_info(id)
    if info == NULL:
        raise PDCError("Could not get info for object")
    return info

cdef void free_info_struct(_pdc_cont_info *info):
    free(<void *> <size_t> info[0].cont_pt[0].pdc[0].name)
    cpdc.PDC_free(<void *> <size_t> info[0].cont_pt[0].pdc)
    cpdc.PDC_free(<void *> <size_t> info[0].cont_pt)
    #broken:
    #free(<void *> <size_t> info[0].cont_info_pub[0].name)
    #cpdc.PDC_free(<void *> <size_t> info[0].cont_info_pub)
    cpdc.PDC_free(<void *> <size_t> info)

class ContainerKVTags(KVTags):
    def __init__(self, cont):
        self.cont = cont
    
    def delete(self, name:bytes):
        raise NotImplementedError("Cannot delete tag from container: https://github.com/hpc-io/pdc/issues/66")
        #if cpdc.PDCcont_del_tag(self.cont._id, name) != 0:
        #    raise PDCError("tag does not exist or could not delete tag")
    
    def get(self, name:bytes):
        cdef void* value_out
        cdef psize_t size_out
        if cpdc.PDCcont_get_tag(self.cont._id, name, &value_out, &size_out) != 0:
            raise PDCError("tag does not exist or could not get tag")
        rtn = PyBytes_FromStringAndSize(<char *> value_out, size_out)
        return rtn
    
    def set(self, name:bytes, value:bytes):
        if cpdc.PDCcont_put_tag(self.cont._id, name, <char *> value, len(value)) != 0:
            raise PDCError("could not set tag")

def to_c_object_list(objects: Union['pdc.Object', Sequence['pdc.Object']]):
    cdef size_t size
    cdef pdcid_t *ids
    if isinstance(objects, pdc.Object):
        size = 1
        ids = <pdcid_t *> malloc_or_memerr(sizeof(pdcid_t))
        ids[0] = objects._id
    else:
        size = len(objects)
        ids = <pdcid_t *> malloc_or_memerr(sizeof(pdcid_t) * size)
        try:
            for i in range(size):
                ids[i] = objects[i]._id
        finally:
            free(ids)
    return <uint64_t> ids, size

class Container:
    '''
    | Containers can contain one or more objects, and objects can be part of one or more containers.
    | Containers can be used to allow objects to persist, and have no other functionality at the moment.
    | Every object must be created belonging to a container.
    '''

    class Lifetime(Enum):
        '''
        The possible lifetimes of containers.
        '''
        PERSISTENT = pdc_lifetime_t.PDC_PERSIST
        TRANSIENT  = pdc_lifetime_t.PDC_TRANSIENT
    
    containers_by_id = WeakValueDictionary()
    
    def __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT, *, _id:Optional[int]=None):
        '''
        __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT)
        :param str name: the name of the container.  Container names should be unique between all processes that use PDC.
        :param Lifetime lifetime: the container's lifetime.
        '''

        cdef pdcid_t id, prop_id
        if _id is not None:
            checktype(_id, 'id', int)
            id = _id
        else:
            checktype(name, 'name', str)
            checktype(lifetime, 'lifetime', type(self).Lifetime)
            
            if name == '':
                raise ValueError("Container name cannot be empty")

            prop_id = cpdc.PDCprop_create(pdc_prop_type_t.PDC_CONT_CREATE, _get_pdcid())
            ctrace('prop_create', prop_id, 'PDC_CONT_CREATE', _get_pdcid())
            if prop_id == 0:
                raise PDCError('Failed to create container property')
            
            if lifetime != type(self).Lifetime.PERSISTENT:
                rtn = cpdc.PDCprop_set_cont_lifetime(prop_id, lifetime.value)
                ctrace('prop_set_cont_lifetime', rtn, prop_id, lifetime)
                if rtn != 0:
                    raise PDCError('Failed to set container lifetime')
            
            id = cpdc.PDCcont_create(name.encode('utf-8'), prop_id)
            ctrace('cont_create', id, name.encode('utf-8'), prop_id)
            if id == 0:
                raise PDCError('Failed to create container')
            
            rtn = cpdc.PDCprop_close(prop_id)
            ctrace('prop_close', rtn, prop_id)
            if rtn != 0:
                raise PDCError('Failed to close container property')
        
        finalize(self, self._finalize, id)
        self._id = id
        type(self).containers_by_id[id] = self

    @staticmethod
    def _finalize(pdcid_t id):
        rtn = cpdc.PDCcont_close(id)
        ctrace('cont_close', rtn, id)
        if rtn != 0:
            raise PDCError('Failed to close container')
    
    @classmethod
    def _fromid(cls, pdcid_t id):
        if id in cls.containers_by_id:
            return cls.containers_by_id[id]
        else:
            return cls(None, None, _id=id)

    @classmethod
    def get(cls, name:str) -> 'Container':
        '''
        Get an existing container by name.
        If you try to get a container that does not exist, the server segfaults and the call blocks indeinitely.

        :param str name: the name of the container.
        :return: The container.
        '''
        cdef pdcid_t id = cpdc.PDCcont_open(name.encode('utf-8'), _get_pdcid())
        if id == 0:
            raise PDCError('Container not found or failed to open container')
        return cls._fromid(id)
    
    def persist(self) -> None:
        '''
        Make this container persistent if it wasn't already.
        '''
        rtn = cpdc.PDCcont_persist(self._id)
        ctrace('cont_persist', rtn, self._id)
        if rtn != 0:
            raise PDCError('Failed to make container persistent')
    
    @property
    def lifetime(self) -> Lifetime:
        '''
        The lifetime of this container. read-only.
        '''
        cdef _pdc_cont_info *info = get_info_struct(self._id)
        try:
            return type(self).Lifetime(info[0].cont_pt[0].cont_life)
        finally:
            free_info_struct(info)
    
    @property
    def name(self) -> str:
        '''
        The name of this container. read-only
        '''
        cdef _pdc_cont_info *info = get_info_struct(self._id)
        try:
            return info[0].cont_info_pub[0].name.decode('utf-8')
        finally:
            free_info_struct(info)
    
    @property
    def tags(self) -> KVTags:
        '''
        The tags of this container. See :class:`KVTags` for more information.

        NOTE: currently, deleting tags from containers is not supported.
        '''
        return ContainerKVTags(self)
    
    def all_local_objects(self) -> Iterable['pdc.Object']:
        '''
        Get an iterable through all objects in this container that have been retrieved by the client, and haven't yet been garbage collected.
        Deleting an object while this iterator is in use may cause undefined behavior.

        :return: An iterable of Objects
        '''
        cdef obj_handle *handle = cpdc.PDCobj_iter_start(self._id)
        ctrace('obj_iter_start', <uint64_t> handle, self._id)

        cdef pdc_obj_info *info
        cdef pdcid_t id
        
        while True:
            rtn = cpdc.PDCobj_iter_null(handle)
            ctrace('obj_iter_null', bool(rtn), <uint64_t> handle)
            if rtn:
                break
            
            info = cpdc.PDCobj_iter_get_info(handle)
            ctrace('obj_iter_get_info', <uint64_t> info, <uint64_t> handle)
            if info == NULL:
                raise PDCError('Failed to get object info')
            
            id = info[0].local_id
            if id == 0:
                raise PDCError('Object local ID missing')
            
            yield pdc.Object._fromid(id)
            
            handle = cpdc.PDCobj_iter_next(handle, self._id)
            ctrace('obj_iter_next', <uint64_t> handle, <uint64_t> handle, self._id)
    
    def _add_objects(self, objects:Union[Sequence['pdc.Object'], 'pdc.Object']):
        '''
        Add objects to this container

        :param object: A single Object, or a sequence of Objects to add.
        '''
        ptr, size = to_c_object_list(objects)
        cdef pdcid_t *ids = <pdcid_t *> <uint64_t> ptr
        try:
            rtn = cpdc.PDCcont_put_objids(self._id, size, ids)
            ctrace('cont_put_objids', rtn, self._id, size, tuple(o._id for o in objects))
            if rtn != 0:
                raise PDCError('Failed to add objects to container')
        finally:
            free(ids)
    
    #TODO: when this is implemented, add back this warning:
    #        In particular, do not write ``container.remove_objects(container.all_local_objects())``
    def _remove_objects(self, objects:Union[Sequence['pdc.Object'], 'pdc.Object']):
        '''
        Remove objects from this container
        
        :param object: A single Object, or a sequence of Objects to add.
        '''
        ptr, size = to_c_object_list(objects)
        cdef pdcid_t *ids = <pdcid_t *> <uint64_t> ptr
        try:
            rtn = cpdc.PDCcont_del_objids(self._id, size, ids)
            ctrace('cont_del_objids', rtn, self._id, size, tuple(o._id for o in objects))
            if rtn != 0:
                raise PDCError('Failed to add objects to container')
        finally:
            free(ids)
    
    def _delete(self):
        '''
        Delete this container.
        Do not access any methods or properties of this object after calling.

        NOTE: this is currently broken, and doesn't actually delete the container.
        '''
        if cpdc.PDCcont_del(self._id) != 0:
            raise PDCError('Failed to delete container')
    
    def __eq__(self, other):
        return isinstance(other, Container) and self._id == other._id
    
    def __hash__(self):
        return hash(self._id)
    
    def create_object(self, name:str, properties:'Object.Properties'):
        '''
        Create a new object, placed in this container.  To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param ObjectProperties properties: An ObjectProperties describing the properties of the object.
        '''
        return pdc.Object(name, properties, self)
    
    def object_from_array(self, name:str, array:npt.ArrayLike, type:Optional[Type]=None, prop:Optional['Object.Properties']=None) -> 'Object':
        '''
        object_from_array(self, name:str, array, type:Optional[Type]=None, prop:Optional['Object.Properties']=None)
        Create a new object, placed in this container, from an array-like object.
        To get an existing object, use Object.get() instead

        :param str name: the name of the object.  Object names should be unique between all processes that use PDC, however, passing in a duplicate name will create the object anyway.
        :param array: the array to create the object from.  It must be a numpy array, or be convertible to a numpy array via numpy.array().
        :param type: If specified, the resulting object will have this type, if all elements of the array fit in this type.
        :param prop: If specified, the app name, time step, and user id will be copied from this properties object to the resulting object's properties.
        '''
        if type is None:
            array = np.asanyarray(array)
        else:
            array = np.asanyarray(array, dtype=type.as_numpy_type())
        
        dtype = array.dtype
        if not dtype.isnative:
            array = array.astype(dtype.newbyteorder('='))
        
        if type is not None:
            obj_type = type
        else:
            obj_type = pdc.Type.from_numpy_type(dtype)
        
        if prop is None:
            obj_prop = pdc.Object.Properties(type=obj_type, dims=array.shape)
        else:
            obj_prop = prop.copy()
            obj_prop.type = obj_type
            obj_prop.dims = array.shape
        
        obj = self.create_object(name, obj_prop)
        obj.set_data(array).wait()
        return obj

def all_local_containers() -> Iterable[Container]:
    '''
    Get an iterable of all containers that have been retrieved by the client, and haven't yet been garbage collected.
    Deleting a container after this function is called, then using the iterator may cause undefined behavior.

    :return: An iterable of Containers
    '''
    cdef cont_handle *handle = cpdc.PDCcont_iter_start()
    ctrace('cont_iter_start', <uint64_t> handle)

    cdef pdc_cont_info *info
    cdef pdcid_t id
    
    while True:
        rtn = cpdc.PDCcont_iter_null(handle)
        ctrace('cont_iter_null', bool(rtn), <uint64_t> handle)
        if rtn:
            break
        
        info = cpdc.PDCcont_iter_get_info(handle)
        ctrace('cont_iter_get_info', <uint64_t> info, <uint64_t> handle)
        if info == NULL:
            raise PDCError('Failed to get container info')
        
        id = info[0].local_id
        if id == 0:
            raise PDCError('Container local ID missing')
        
        yield Container._fromid(id)
        
        handle = cpdc.PDCcont_iter_next(handle)
        ctrace('cont_iter_next', <uint64_t> handle, <uint64_t> handle)
