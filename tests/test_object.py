import pdc
import pytest
import numpy as np
from pdc.main import PDCError

def test_object_attrs():
    cont = pdc.Container('testobject', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(dims=(3, 4, 5), type=pdc.Type.FLOAT)
    obj = cont.create_object('testobject', prop)

    assert obj.name == 'testobject'
    assert obj.dims == (3, 4, 5)
    assert obj.type == pdc.Type.FLOAT

    prop.dims = (4, 5, 6)

    assert obj.dims == (3, 4, 5)

    #prop_copy = obj.get_properties()
    #assert prop_copy.dims == (3, 4, 5)
    #assert prop_copy.type == pdc.Type.FLOAT

def test_int16():    
    cont = pdc.Container('testint16')
    prop = pdc.Object.Properties(dims=(3, 4, 5), type=pdc.Type.INT16)
    obj = cont.create_object('testint16obj', prop)

    assert obj.type == pdc.Type.INT16

def test_from_np():
    cont = pdc.Container('testnp')
    
    assert np.array_equal(cont.object_from_array('testnp_a', range(16)).get_data().wait(),  np.array(range(16)))
    assert np.array_equal(cont.object_from_array('testnp_b', [[2]]).get_data().wait(), np.array([[2]]))

    obj = cont.object_from_array('testnp_b', [[2, 3], [4, 5]], pdc.Type.INT8, pdc.Object.Properties(dims=1, type=pdc.Type.INT8, app_name='merp', time_step=9, user_id=90))
    assert obj.dims == (2, 2)
    assert obj.type == pdc.Type.INT8

    obj = cont.object_from_array('testnp_c', [[2.4, 3.7]])
    assert obj.type in (pdc.Type.FLOAT, pdc.Type.DOUBLE)

def test_uint8():
    cont = pdc.Container('testuint8')
    prop = pdc.Object.Properties(dims=(3, 4, 5), type=pdc.Type.UINT8)
    obj = cont.create_object('testuint8obj', prop)

    assert obj.type == pdc.Type.UINT8

    data = np.array([[[x for x in range(5)] for _ in range(4)] for _ in range(3)], dtype=np.uint8)
    obj.set_data(data).wait()
    retrieved_data = obj.get_data().wait()
    assert np.array_equal(data, retrieved_data)

def test_object_get_non_existent():
    with pytest.raises(PDCError):
        obj = pdc.Object.get('non_existent_object')
