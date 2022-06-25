import pdc
from pdc import Object, region
import numpy as np
import mpi4py
import asyncio

async def main():
    rank = mpi4py.MPI.COMM_WORLD.Get_rank()

    pdc.init()
    cont = pdc.Container()
    prop = Object.Properties(dims=(0,))
    obj1 = Object('o1', prop, cont)
    obj2 = Object('o2', prop, cont)

    obj1.tags['key1'] = 'value1'
    obj1.tags['key2'] = '2'
    obj2.tags['key2'] = '2'
    obj2.tags['key3'] = '3.45'

    def test_query(name, value, expected):
        objects = pdc.tag_query(name, value)
        print(f'found {len(objects)} objects with tag {name}={value}')
        assert len(objects) == expected
        for obj in objects:
            print(obj.name)
            assert obj.tags[name] == value
    
    test_query('key1', 'value1', 1)
    test_query('key2', '2', 2)
    test_query('key3', '3.45', 1)
    test_query('key4', '4', 0)
    test_query('key1', 'derp', 0)

asyncio.run(main())