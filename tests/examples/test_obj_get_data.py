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
    obj1 = Object(f'o1_{rank}', prop, cont)

    #set all data to data
    obj1.set_data(data).wait_for_result()

    data = np.full(128, 2.0, dtype=np.float64)
    obj2 = Object(f'o2_{rank}', prop, cont)
    obj2.set_data(data).wait_for_result()

    #test object values
    for val in obj1.get_data().wait_for_result():
        assert val == 1.0
    for val in obj2.get_data().wait_for_result():
        assert val == 2.0

@pytest.mark.skip
def test_obj_get_data():
    asyncio.run(main())