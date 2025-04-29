'''
This script is used to simulate VPIC I/O operations with the Proactive Data Containers (PDC) framework.
MPI is enabled in this script.
'''
'''
This script is used to simulate VPIC I/O operations with the Proactive Data Containers (PDC) framework.
MPI is enabled in this script.
'''

import os
import sys
import time
import datetime
import psutil
import numpy as np
import pandas as pd
from mpi4py import MPI
from pdc import *
from monitor_resource_utilization_disk_io import start_monitoring, stop_monitoring

# MPI initialization
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

# Define the number of particles.
NPARTICLES = 8388608
X_DIM, Y_DIM, Z_DIM = 64, 64, 64

OUTPUT_DIR = f"vpic_output_mpi_with_pdc_rank_{size}_{NPARTICLES}particles_{X_DIM}dims_results"
CSV_FILE = f"{OUTPUT_DIR}/vpicio_mpi_rank_{rank}_{NPARTICLES}particles_{X_DIM}dims_results.csv"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def check_pdc_server():
    import subprocess
    try:
        result = subprocess.run(["pgrep", "-f", "pdc_server.exe"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Rank {rank}: PDC server is running.")
        else:
            print(f"❌ Rank {rank}: PDC server is NOT running!")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Rank {rank}: Error checking PDC server: {e}")
        sys.exit(1)

def get_system_resources():
    cpu_usage = round(psutil.cpu_percent(interval=1), 3)
    memory_usage = round(psutil.virtual_memory().percent, 3)
    disk_usage = round(psutil.disk_usage('/').percent, 3)
    swap_usage = round(psutil.swap_memory().percent, 3)
    disk_io = psutil.disk_io_counters()
    proc_io = psutil.Process().io_counters()
    return {
        "cpu": cpu_usage,
        "memory": memory_usage,
        "disk": disk_usage,
        "swap": swap_usage,
        "disk_read_bytes": disk_io.read_bytes,
        "disk_write_bytes": disk_io.write_bytes,
        "disk_read_count": disk_io.read_count,
        "disk_write_count": disk_io.write_count,
        "proc_read_bytes": proc_io.read_bytes,
        "proc_write_bytes": proc_io.write_bytes
    }

def save_results_to_csv(operation, time_taken, rank, res):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data = pd.DataFrame([[timestamp, rank, size, operation, f"{time_taken:.3f}",
                          f"{res['cpu']:.3f}", f"{res['memory']:.3f}", f"{res['disk']:.3f}", f"{res['swap']:.3f}",
                          res['disk_read_bytes'], res['disk_write_bytes'],
                          res['disk_read_count'], res['disk_write_count'],
                          res['proc_read_bytes'], res['proc_write_bytes']]],
                        columns=["Timestamp", "Rank", "Total Ranks", "Operation", "Time Taken (s)",
                                 "CPU Usage (%)", "Memory Usage (%)", "Disk Usage (%)", "Swap Usage (%)",
                                 "Disk Read Bytes", "Disk Write Bytes",
                                 "Disk Read Count", "Disk Write Count",
                                 "Proc Read Bytes", "Proc Write Bytes"])
    data.to_csv(CSV_FILE, mode='a', header=not os.path.exists(CSV_FILE), index=False)

def main():
    check_pdc_server()

    local_particles = NPARTICLES
    total_particles = local_particles * size
    offset = rank * local_particles

    # Broadcast timestamp for consistent naming
    timestamp = int(time.time()) if rank == 0 else None
    timestamp = comm.bcast(timestamp, root=0)
    container_name = f"PDC-container-dims{X_DIM}-{timestamp}"

    if len(sys.argv) == 2:
        local_particles = int(sys.argv[1])
        total_particles = local_particles * size
        offset = rank * local_particles
        if rank == 0:
            print(f"📌 Writing {total_particles} total particles using {size} processes.")

    comm.Barrier()
    init()

    # Create or open container
    container = None
    if rank == 0:
        try:
            container = Container(name=container_name, lifetime=Container.Lifetime.PERSISTENT)
            print(f"✅ Rank {rank}: Container '{container_name}' created.")
        except PDCError as e:
            print(f"❌ Rank {rank}: Error creating container: {e}")
            sys.exit(1)

    comm.Barrier()

    if rank != 0:
        for attempt in range(5):
            try:
                container = Container.get(container_name)
                print(f"✅ Rank {rank}: Opened container '{container_name}'.")
                break
            except PDCError as e:
                print(f"⚠️ Rank {rank}: Retry {attempt}: Could not get container: {e}")
                time.sleep(1)
        else:
            print(f"❌ Rank {rank}: Failed to open container after retries.")
            sys.exit(1)

    comm.Barrier()

    # Define object properties
    user_id = os.getuid()
    global_dims = (total_particles,)
    float_prop = Object.Properties(dims=global_dims, type=Type.FLOAT, user_id=user_id, app_name="VPICIO")
    int_prop = Object.Properties(dims=global_dims, type=Type.INT32, user_id=user_id, app_name="VPICIO")

    object_defs = {
        "object_xx": float_prop,
        "object_yy": float_prop,
        "object_zz": float_prop,
        "object_pxx": float_prop,
        "object_pyy": float_prop,
        "object_pzz": float_prop,
        "object_id11": int_prop,
        "object_id22": int_prop,
    }

    objects = {}

    if rank == 0:
        for name, prop in object_defs.items():
            try:
                objects[name] = container.create_object(name, prop)
            except PDCError as e:
                print(f"❌ Rank {rank}: Failed creating object '{name}': {e}")
                sys.exit(1)

    comm.Barrier()

    if rank != 0:
        for name in object_defs:
            for attempt in range(5):
                try:
                    objects[name] = Object.get(name)
                    break
                except PDCError as e:
                    print(f"⚠️ Rank {rank}: Retry {attempt}: Could not get object '{name}': {e}")
                    time.sleep(1)
            else:
                print(f"❌ Rank {rank}: Failed to get object '{name}' after retries.")
                sys.exit(1)

    comm.Barrier()

    # VPIC-style data init
    id1 = np.arange(offset, offset + local_particles, dtype=np.int32)
    id2 = id1 * 2
    x = np.random.rand(local_particles).astype(np.float32) * X_DIM
    y = np.random.rand(local_particles).astype(np.float32) * Y_DIM
    z = ((id1 / total_particles) * Z_DIM).astype(np.float32)
    px = np.random.rand(local_particles).astype(np.float32) * X_DIM
    py = np.random.rand(local_particles).astype(np.float32) * Y_DIM
    pz = ((id2 / total_particles) * Z_DIM).astype(np.float32)

    comm.Barrier()

    # Write
    start_time = time.perf_counter()
    monitor_thread = start_monitoring()
    print(f"🔄 Rank {rank}: Starting write.")

    for name, data in zip(object_defs, [x, y, z, px, py, pz, id1, id2]):
        try:
            transfer = objects[name].set_data(data, region=region[offset:offset + local_particles])
            transfer.wait()
        except PDCError as e:
            print(f"❌ Rank {rank}: Write failed for '{name}': {e}")
            sys.exit(1)

    stop_monitoring(monitor_thread)
    time_taken = round(time.perf_counter() - start_time, 3)
    res = get_system_resources()
    save_results_to_csv("Write", time_taken, rank, res)
    print(f"📝 Rank {rank}: Write completed in {time_taken:.3f}s.")

    comm.Barrier()

    # Read
    start_time = time.perf_counter()
    monitor_thread = start_monitoring()
    print(f"🔄 Rank {rank}: Starting read.")

    for name in object_defs:
        try:
            transfer = objects[name].get_data(region=region[offset:offset + local_particles])
            transfer.wait()
        except PDCError as e:
            print(f"❌ Rank {rank}: Read failed for '{name}': {e}")
            sys.exit(1)

    stop_monitoring(monitor_thread)
    time_taken = round(time.perf_counter() - start_time, 3)
    res = get_system_resources()
    save_results_to_csv("Read", time_taken, rank, res)
    print(f"📖 Rank {rank}: Read completed in {time_taken:.3f}s.")

    comm.Barrier()

    # Cleanup: close and delete all objects + container (only by rank 0)
    if rank == 0:
        print(f"🧹 Rank {rank}: Cleaning up resources.")
        for name, obj in objects.items():
            try:
                obj.delete()
                print(f"✅ Object '{name}' deleted.")
            except PDCError as e:
                print(f"⚠️ Failed to delete object '{name}': {e}")
        '''
        try:
            container.delete()
            print(f"✅ Container '{container_name}' deleted.")
        except PDCError as e:
            print(f"⚠️ Failed to delete container: {e}")
        '''
    comm.Barrier()
    MPI.Finalize()

if __name__ == "__main__":
    sys.exit(main())
