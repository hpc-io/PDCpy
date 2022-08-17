import pdc
import pytest
import os
import numpy as np

def test_prop_dims():
    prop = pdc.Object.Properties(dims=128, type=pdc.Type.DOUBLE)
    assert prop.dims == (128,)

    prop.dims = (1, 2, 3, 4, 5)
    assert prop.dims == (1, 2, 3, 4, 5)

    with pytest.raises(ValueError):
        prop.dims = ()
    
    with pytest.raises(TypeError):
        prop.dims = 'hello'
    
    with pytest.raises(TypeError):
        prop.dims = (1.0,)

    with pytest.raises(TypeError):
        prop.dims = [3, 2, 3]
    
    with pytest.raises(ValueError):
        prop.dims = (-1, 2, 3)

def test_prop_type():
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.DOUBLE)
    assert prop.type == pdc.Type.DOUBLE

    prop.type = pdc.Type.UINT32
    assert prop.type == pdc.Type.UINT32
    
    with pytest.raises(TypeError):
        prop.type = 0

def test_prop_time_step():
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.DOUBLE)
    assert prop.time_step == 0

    prop.time_step = 2
    assert prop.time_step == 2
    
    with pytest.raises(TypeError):
        prop.time_step = 1.0
    
    with pytest.raises(OverflowError):
        prop.time_step = -1
    
    with pytest.raises(OverflowError):
        prop.time_step = 2**48

def test_prop_user_id(): 
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.DOUBLE)
    assert prop.user_id == os.getuid()

    prop.user_id = 233322
    assert prop.user_id == 233322

    with pytest.raises(TypeError):
        prop.user_id = 3.2
    
    with pytest.raises(OverflowError):
        prop.user_id = -1
    
    with pytest.raises(OverflowError):
        prop.user_id = 2**48

def test_app_name():
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.DOUBLE)
    assert prop.app_name == ''

    prop.app_name = 'test'
    assert prop.app_name == 'test'

    prop.app_name = '∁∂∃∄∅∆∇'
    assert prop.app_name == '∁∂∃∄∅∆∇'

    with pytest.raises(TypeError):
        prop.app_name = b'test'
    
    with pytest.raises(TypeError):
        prop.app_name = -1

def test_full_constructor():
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.INT8, time_step=2, user_id=3333, app_name='test')
    assert prop.dims == (128,)
    assert prop.type == pdc.Type.INT8
    assert prop.time_step == 2
    assert prop.user_id == 3333
    assert prop.app_name == 'test'

def test_copy():
    old_prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.INT8, time_step=2, user_id=3333, app_name='test')
    prop = old_prop.copy()
    assert prop.dims == (128,)
    assert prop.type == pdc.Type.INT8
    assert prop.time_step == 2
    assert prop.user_id == 3333
    assert prop.app_name == 'test'

def test_equals():
    prop = pdc.Object.Properties(dims=(128,), type=pdc.Type.INT8, time_step=2, user_id=3333, app_name='test')
    prop2 = pdc.Object.Properties(dims=(128,), type=pdc.Type.INT8, time_step=2, user_id=3333, app_name='test')
    assert prop == prop2
    assert prop2 == prop
    assert hash(prop) == hash(prop2)

    prop2.dims = (1, 2, 3, 4, 5)
    assert prop != prop2

def test_np_type():
    prop = pdc.Object.Properties(dims=90, type=np.int8)
    assert prop.type == pdc.Type.INT8

    prop.type = np.int32
    assert prop.type == pdc.Type.INT32