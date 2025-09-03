PDC (Proactive Data Containers) is a software-defined data management system meant for high performance computing systems with several layers of storage, aiming to minimize overhead of moving data between memory and storage layers.

Its existing interface is written in C, but with the rise of Python in scientific computing applications, PDC would be much more accessible with a python interface.

This repository contains that interface, its documentation, and unit tests.

This project was originally developed as part of [Google Summer of Code 2022](https://summerofcode.withgoogle.com/programs/2022) ([project page](https://summerofcode.withgoogle.com/programs/2022/projects/aXtefGUz)), and was supported by [CROSS](https://cross.ucsc.edu/).

[More information about PDC](https://github.com/hpc-io/pdc)

[Documentation](https://hpc-io.github.io/PDCpy/)

# How To Install

PDCpy is compatible with openmpi and mpich. If neither compiler is installed, it will attempt to compile without mpi support, which will fail if you compile pdc with mpi support.

1.  **Install PDC**: Follow the instructions in the [PDC document](https://pdc.readthedocs.io/en/latest/getting_started.html#installing-pdc-from-source-code)
    After installing PDC, ensure the following:
    * `$PDC_DIR` and `$MERCURY_DIR` are set to their correct locations.
    * `pdc_server` is in your `PATH`.
    * `$LD_LIBRARY_PATH` has the location of `libpdc.so`.

2.  **Install PDCpy**:
    ```bash
    pip install PDCpy
    ```
