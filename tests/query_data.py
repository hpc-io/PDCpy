from datetime import time
import sys
import pdc
from pdc import Object, region
import numpy as np
import mpi4py
import asyncio

comm = mpi4py.MPI.COMM_WORLD

#size is in number of floating point numbers, not bytes, unlike the original

async def main():
    if len(sys.argv) != 3:
        print(f'Usage: srun -n {sys.argv[0]} obj_name size')
        return
    
    rank = comm.Get_rank()
    size = comm.Get_size()
    obj_name = sys.argv[1]
    length = int(sys.argv[2])
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

asyncio.run(main())