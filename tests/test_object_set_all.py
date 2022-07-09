import pytest
import pdc
from pdc import region
import numpy as np

def test_set_all():
    cont = pdc.Container('set_all_cont')
    prop = pdc.Object.Properties(dims = (8, 6), type=pdc.Type.INT16)
    obj = pdc.Object('set_all_obj', prop, cont)
    
    data = np.full((8, 6), 42, dtype=np.int16)
    obj.set_data(data).wait_for_result()

    assert np.array_equal(obj.get_data().wait_for_result(), data)