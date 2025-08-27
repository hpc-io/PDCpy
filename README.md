PDC (Proactive Data Containers) is a software-defined data management system meant for high performance computing systems with several layers of storage, aiming to minimize overhead of moving data between memory and storage layers.

Its existing interface is written in C, but with the rise of Python in scientific computing applications, PDC would be much more accessible with a python interface.

This repository contains that interface, its documentation, and unit tests.

This project was originally developed as part of [Google Summer of Code 2022](https://summerofcode.withgoogle.com/programs/2022) ([project page](https://summerofcode.withgoogle.com/programs/2022/projects/aXtefGUz)), and was supported by [CROSS](https://cross.ucsc.edu/).

[More information about PDC](https://github.com/hpc-io/pdc)

[Documentation](https://hpc-io.github.io/PDCpy/)

# How To Install

PDCpy is compatible with openmpi and mpich. If neither compiler is installed, it will attempt to compile without mpi support, which will fail if you compile pdc with mpi support.

1.  **Install PDC**: Follow the instructions on the PDC repository:
    ```
    https://pdc.readthedocs.io/en/latest/getting_started.html#installing-pdc-from-source-code
    ```
    After installing PDC, ensure the following:
    *   `$PDC_DIR` and `$MERCURY_DIR` are set to their correct locations.
    *   `pdc_server` is on your `PATH`.
    *   `$LD_LIBRARY_PATH` has the location of `libpdc.so`.
    *   You installed the `develop` branch, NOT the `stable` branch.

2.  **Install PDCpy**:
    ```bash
    pip install PDCpy
    ```

## Manual Build Instructions

If you prefer to build PDCpy manually, follow these steps:

1.  **Install build dependencies**:
    ```bash
    pip install Cython numpy setuptools wheel
    ```
2.  **Build the Cython extensions**:
    ```bash
    python3 setup.py build_ext --inplace
    ```
    This will compile the Cython source files and place the compiled `.so` (or `.pyd` on Windows) files directly in the `pdc/` directory.

