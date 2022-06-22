from enum import Enum
from typing import Iterable

from pdc.cpdc cimport pdc_lifetime_t
import pdc

class Container:
    '''
    A PDC container
    '''

    class Lifetime(Enum):
        '''
        An emuneration of the lifetimes of containers.
        '''
        PERSISTENT = pdc_lifetime_t.PDC_PERSIST
        TRANSIENT  = pdc_lifetime_t.PDC_TRANSIENT

    
    def __init__(self, name:str, lifetime:Lifetime=Lifetime.TRANSIENT):
        '''
        :param str name: the name of the container.  Container names should be unique between all processes that use PDC.
        :param Lifetime lifetime: the container's lifetime.
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


def all_containers() -> Iterable[Container]:
    '''
    Get an iterable of all containers that have been retrieved by the client, and haven't yet been garbage collected.
    Deleting a container after this function is called, then using the iterator may cause undefined behavior.

    :return: An iterable of Containers
    '''
    pass
