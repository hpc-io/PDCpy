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
    