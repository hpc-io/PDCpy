import pdc
from pdc import Object
import numpy as np

def test_obj_get_data():
    #create temporary container
    cont = pdc.Container('cont', lifetime=pdc.Container.Lifetime.TRANSIENT)

    #create np data array of 128 doubles
    data = np.full(128, 1.0, dtype=np.float64)

    #Method 1: create object from array:
    obj1 = cont.object_from_array('objectexample_obj1', data)

    out_data = obj1.get_data().wait()
    for val in out_data:
        assert val == 1.0

    

    #Method 2: create object from properties:
    #create object property
    prop = Object.Properties(dims=128, type=pdc.Type.DOUBLE)
    #alternatively:
    prop = Object.Properties(dims=128, type=np.double)

    #property objects can be changed like so:
    prop.app_name = 'objectexample'

    #create object
    obj2 = cont.create_object('objectexample_obj2', prop)

    #set all data to data
    obj2.set_data(data).wait()

    #test data values
    out_data = obj2.get_data().wait()
    for val in out_data:
        assert val == 1.0
