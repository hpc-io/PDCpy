import pytest
import pdc
from pdc import Object, region
import numpy as np
from mpi4py import MPI
import asyncio

async def main():
    rank = MPI.COMM_WORLD.Get_rank()

    cont = pdc.Container('cont')

    #create np data array of 128 doubles
    data = np.full(128, 1.0, dtype=np.float64)

    #create object property
    prop = Object.Properties(dims=128, type=pdc.Type.DOUBLE)

    #create object
    obj1 = cont.create_object(f'o1_{rank}', prop)

    #set all data to data
    obj1.set_data(data).wait()

    data = np.full(128, 2.0, dtype=np.float64)
    obj2 = cont.create_object(f'o2_{rank}', prop)
    obj2.set_data(data).wait()

    #test object values
    for val in obj1.get_data().wait():
        assert val == 1.0
    for val in obj2.get_data().wait():
        assert val == 2.0

def test_obj_get_data():
    asyncio.run(main())