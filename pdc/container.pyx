from enum import Enum
from typing import Iterable, Optional
from weakref import finalize

from .main import KVTags, checktype, _get_pdcid, PDCError, ctrace
from pdc.cpdc cimport pdc_lifetime_t, pdc_prop_type_t, pdcid_t, _pdc_cont_info, psize_t
import pdc
cimport pdc.cpdc as cpdc
from cpython.bytes cimport PyBytes_FromStringAndSize

cdef _pdc_cont_info get_info_struct(pdcid_t id):
    cdef _pdc_cont_info *private_struct = cpdc.PDC_cont_get_info(id)
    if private_struct == NULL:
        raise PDCError("Could not get info for object")
    return private_struct[0]

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

class Container:
    '''
    Containers can contain one or more objects, and objects can be part of one or more containers.
    Containers are mainly used to allow objects to persist, and have very little other functionality at the moment.
    '''

    class Lifetime(Enum):
        '''
        An emuneration of the lifetimes of containers.
        '''
        PERSISTENT = pdc_lifetime_t.PDC_PERSIST
        TRANSIENT  = pdc_lifetime_t.PDC_TRANSIENT
    
    containers_by_id = {}
    
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
            checktype(lifetime, 'lifetime', Container.Lifetime)
            
            if name == '':
                raise ValueError("Container name cannot be empty")

            prop_id = cpdc.PDCprop_create(pdc_prop_type_t.PDC_CONT_CREATE, _get_pdcid())
            ctrace('prop_create', prop_id, 'PDC_CONT_CREATE', _get_pdcid())
            if prop_id == 0:
                raise PDCError('Failed to create container property')
            
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

        :param str name: the name of the container.
        :return: the container.
        :rtype: Container
        '''
        cdef pdcid_t id = cpdc.PDCcont_open(name.encode('utf-8'), _get_pdcid())
        if id == 0:
            raise PDCError('Container not found or failed to open container')
        return cls._fromid(id)
    
    def persist(self):
        '''
        Make this container persistent if it wasn't already.
        '''
        if cpdc.PDCcont_persist(self._id) != 0:
            raise PDCError('Failed to make container persistent')
    
    @property
    def lifetime(self):
        '''
        The lifetime of this container. read-only.
        '''
        return type(self).Lifetime((get_info_struct(self._id).cont_pt)[0].cont_life)
    
    @property
    def name(self):
        '''
        The name of this container. read-only
        '''
        return (get_info_struct(self._id).cont_info_pub)[0].name.decode('utf-8')
    
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
        In particular, do not write ``container.remove_objects(container.all_local_objects())``

        :return: An iterable of Objects
        '''
        pass
    
    def add_objects(self, objects:Iterable['pdc.Object']):
        '''
        Add objects to this container

        :param object: An iterable of Objects to add.
        '''
        pass
    
    def remove_objects(self, objects:Iterable['pdc.Object']):
        '''
        Remove objects from this container
        
        :param objects: An iterable of Objects to remove.
        '''
        pass
    
    def _delete(self):
        '''
        Delete this container.
        Do not access any methods or properties of this object after calling.

        NOTE: this is currently broken, and doesn't actually delete the container.
        '''
        if cpdc.PDCcont_del(self._id) != 0:
            raise PDCError('Failed to delete container')

def all_local_containers() -> Iterable[Container]:
    '''
    Get an iterable of all containers that have been retrieved by the client, and haven't yet been garbage collected.
    Deleting a container after this function is called, then using the iterator may cause undefined behavior.

    :return: An iterable of Containers
    '''
    pass
