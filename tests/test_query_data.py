from datetime import time
import sys
import pdc
from pdc import Object, region
import numpy as np
from mpi4py import MPI
import asyncio
import pytest

#size is in number of floating point numbers, not bytes, unlike the original

async def main(obj_name:str, length:int):
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    cont = pdc.Container()
    prop = Object.Properties(
        (length,),
        pdc.Type.DOUBLE,
        time_step = 0,
        app_name = 'DataServerTest'
    )
    if rank == 0:
        obj = Object(obj_name, prop, cont)
    comm.Barrier()
    if rank != 0:
        obj = Object.get(obj_name)
    
    my_data_length = length // size
    my_region = region[rank * my_data_length : (rank + 1) * my_data_length]
    data = np.fromiter(range(rank*1000, rank*1000+my_data_length), dtype=np.int32)

    comm.Barrier()
    start = time.time()

    await obj.set_data(data, my_region)

    comm.Barrier()
    end = time.time()
    print(f'Rank {rank} set data in {end - start} seconds')

    query = ((obj.data < 1000) | (obj.data >= 2000 & obj.data < 3000) | (obj.data >= 5000 & obj.data < 7000))
    print(query.get_result(my_region)[obj])

#skip this test
@pytest.mark.skip
def test_query():
    asyncio.run(main('test_query', 100000))