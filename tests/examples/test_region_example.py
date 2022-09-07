import pdc
import pdc.main
import numpy as np
import pytest

def test_region_example():
    cont = pdc.Container('region_example_cont', lifetime=pdc.Container.Lifetime.TRANSIENT)

    data = [
        [2, 7, 6],
        [9, 5, 1],
        [4, 3, 8]
    ]

    obj = cont.object_from_array('region_example_obj', data)

    data1 = obj.get_data(pdc.region[:2]).wait() # [[2, 7, 6], [9, 5, 1]]
    assert np.array_equal(data1, [[2, 7, 6], [9, 5, 1]])
    data2 = obj.get_data(pdc.region[0, :2]).wait() # [[2, 7]]
    assert np.array_equal(data2, [[2, 7]])
