import re
import pdc
import pytest
import numpy as np
from pdc import region

def test_transfer_color_by_number():
    #end result:
    #11111111
    #11111111
    #32244444
    #32244444
    #02205000
    #02205660
    #02200000

    cont = pdc.Container('test_transfer_color_by_number', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(dims=(8, 8), type=pdc.Type.INT8)
    obj1 = cont.create_object('colorbynumobj', prop)

    obj1.set_data(np.zeros((8, 8), dtype=np.int8)).wait()
    requests = []
    requests.append(obj1.set_data(np.full((2, 8), 1, dtype=np.int8), region[:2, :]))
    requests.append(obj1.set_data(np.full((6, 2), 2, dtype=np.int8), region[2:, 1:3]))
    requests.append(obj1.set_data(np.full((2, 1), 3, dtype=np.int8), region[2:4, :1]))
    requests.append(obj1.set_data(np.full((2, 5), 4, dtype=np.int8), region[2:4, 3:]))
    requests.append(obj1.set_data(np.full((2, 1), 5, dtype=np.int8), region[4:6, 4]))
    requests.append(obj1.set_data(np.full(2, 6, dtype=np.int8), region[6, 5:7]))

    for req in requests:
        req.wait()
    
    all_data = obj1.get_data().wait()
    expected =         np.array([[1, 1, 1, 1, 1, 1, 1, 1],
                                 [1, 1, 1, 1, 1, 1, 1, 1],
                                 [3, 2, 2, 4, 4, 4, 4, 4],
                                 [3, 2, 2, 4, 4, 4, 4, 4],
                                 [0, 2, 2, 0, 5, 0, 0, 0],
                                 [0, 2, 2, 0, 5, 0, 0, 0],
                                 [0, 2, 2, 0, 0, 6, 6, 0],
                                 [0, 2, 2, 0, 0, 0, 0, 0]])
    assert np.array_equal(all_data, expected)