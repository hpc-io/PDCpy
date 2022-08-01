import pdc
from pdc import Region, region
import pytest
import os

def test_region_validation():
    r1 = region[2]
    r2 = region[2:4]
    r3 = region[2:4, 3:7, 9:10]
    r4 = region[:, :, :]
    r5 = region[:2, 1:, :]
    r6 = region[:]
    r7 = region[:, 3, 1:9:1, 7]

    #Actually IndexError:
    #with pytest.raises(ValueError):
    #    Region()
    
    with pytest.raises(OverflowError):
        region[-1]
    
    with pytest.raises(OverflowError):
        region[:, -1:-2]
    
    with pytest.raises(ValueError):
        region[::3]
    
    with pytest.raises(ValueError):
        region[5:4]
    
    with pytest.raises(ValueError):
        region[5:5]

def test_absolute():
    assert region[:].get_absolute((3, 4)) == region[0:3, 0:4]
    assert region[:2, 6:].get_absolute((10, 10)) == region[0:2, 6:10]
    
    assert not region[:].is_absolute()
    assert not region[:2, 6:].is_absolute()
    assert not region[2:3, 4:].is_absolute()
    assert region[2].is_absolute()
    assert region[2:3, 4:9].is_absolute()
    assert region[:].get_absolute((3, 4)).is_absolute()

def test_hash_eq():
    assert region[:] == region[:]
    assert region[:] != region[:, :]

    assert hash(region[3]) == hash(region[3])
    assert hash(region[:]) != hash(region[:, :])

def test_repr():
    assert repr(region[3, 4:, :5, 6:7]) == 'region[3:4, 4:, :5, 6:7]'
    assert str(region[3, 4:, :5, 6:7]) == 'region[3:4, 4:, :5, 6:7]'