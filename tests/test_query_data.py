from datetime import time
import sys
import pdc
from pdc import Object, region
import numpy as np
import asyncio
import pytest

#size is in number of floating point numbers, not bytes, unlike the original

def main(obj_name:str, length:int):
    cont = pdc.Container(lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = Object.Properties(
        (length,),
        pdc.Type.DOUBLE,
        time_step = 0,
        app_name = 'DataServerTest'
    )
    obj = cont.create_object(obj_name, prop)
    data = np.fromiter(range(1000), dtype=np.int32)
    start = time.time()
    obj.set_data(data)

    end = time.time()
    print(f'Set data in {end - start} seconds')

    query = ((obj.data < 1000) | (obj.data >= 2000 & obj.data < 3000) | (obj.data >= 5000 & obj.data < 7000))
    print(query.get_result()[obj])

@pytest.mark.skip
def test_query():
    main('test_query', 100000)