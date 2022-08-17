PDC (Proactive Data Containers) is a software-defined data management system meant for high performance computing systems with several layers of storage, aiming to minimize overhead of moving data between memory and storage layers.

Its existing interface is written in C, but with the rise of Python in scientific computing applications, PDC would be much more accessible with a python interface.

This repository contains that interface, its documentation, and unit tests.

This project is part of [Google Summer of Code 2022](https://summerofcode.withgoogle.com/programs/2022) ([project page](https://summerofcode.withgoogle.com/programs/2022/projects/aXtefGUz))

Thanks to [Houjun Tang](https://github.com/houjun) for answering my questions about PDC while developing the project.

Thanks to [CROSS](https://cross.ucsc.edu/) for supporting PDCpy through GSoC

[More information about PDC](https://sdm.lbl.gov/pdc/about.html)

[Documentation](https://hpc-io.github.io/PDCpy/)

# How To Install

PDCpy is compatible with openmpi and mpich.  If neither compiler is installed, it will attempt to compile without mpi support, which will fail if you compile pdc with mpi support.

First, follow the instructions on the pdc repository
https://github.com/hpc-io/pdc/tree/develop
*Make sure you use the develop branch* (on step 2 of the pdc installation, checkout develop instead)

After you install pdc, make sure all of the following are true:
- $PDC_DIR and $MERCURY_DIR are set to their correct locations
- pdc_server.exe is on your PATH
- $LD_LIBRARY_PATH has the location of libpdc.so
- You installed the develop branch, NOT the stable branch

Then, run:
`pip install PDCpy`
