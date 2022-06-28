from enum import Enum
from typing import Iterable, Optional

from .main import KVTags
from pdc.cpdc cimport pdc_lifetime_t
import pdc

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

    
    def __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT, _fromid:Optional[int]=None):
        '''
        __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT)
        :param str name: the name of the container.  Container names should be unique between all processes that use PDC.
        :param Lifetime lifetime: the container's lifetime.
        '''
        pass
    
    @staticmethod
    def get(name:str) -> 'Container':
        '''
        Get an existing container by name.

        :param str name: the name of the container.
        :return: the container.
        :rtype: Container
        '''
        pass
    
    def persist():
        '''
        Make this container persistent if it wasn't already.
        '''
        pass
    
    @property
    def lifetime():
        '''
        The lifetime of this container
        read-only
        '''
        pass
    
    @property
    def tags(self) -> KVTags:
        '''
        Get the tags of this Object.  See :class:`KVTags` for more info
        '''
        pass

    
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
    
    def delete(self):
        '''
        Remove all objects in this container (?), then delete the container.
        Do not access any methods or properties of this object after calling.
        '''
        pass


def all_local_containers() -> Iterable[Container]:
    '''
    Get an iterable of all containers that have been retrieved by the client, and haven't yet been garbage collected.
    Deleting a container after this function is called, then using the iterator may cause undefined behavior.

    :return: An iterable of Containers
    '''
    pass
