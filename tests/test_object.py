import pdc
import pytest

def test_object_attrs():
    cont = pdc.Container('testobject')
    prop = pdc.Object.Properties(dims=(3, 4, 5), type=pdc.Type.FLOAT)
    obj = pdc.Object('testobject', prop, cont)

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
    obj = pdc.Object('testint16obj', prop, cont)

    assert obj.type == pdc.Type.INT16
