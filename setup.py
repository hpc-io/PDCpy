from setuptools import Extension, setup, find_packages
import os
import sys
import os.path
from Cython.Build import cythonize
import shutil
import subprocess

def get_env_or_exit(name):
    try:
        value = os.environ[name]
    except KeyError:
        sys.exit('Environment variable %s not set. Aborting' % name)
    return value

PDC_DIR = os.path.join(*os.path.split(get_env_or_exit("PDC_DIR"))[:-1])
MERCURY_DIR = get_env_or_exit("MERCURY_DIR")

path = shutil.which('mpicc')
if not path:
    print("mpicc not found on PATH. Attempting to compile without MPI support.")
    mpi_build_args = []
    mpi_link_args = []
elif subprocess.run(['mpicc', '-compile_info']).returncode == 0:
    print("Compiling with mpich")
    mpi_build_args = os.popen('mpicc -compile_info').read().strip().split()[1:]
    mpi_link_args = os.popen('mpicc -link_info').read().strip().split()[1:]
elif subprocess.run(['mpicc', '--showme:compile']).returncode == 0:
    print("Compiling with openmpi")
    mpi_build_args = os.popen('mpicc --showme:compile').read().strip().split()
    mpi_link_args = os.popen('mpicc --showme:link').read().strip().split()
else:
    print("mpicc is neither openmpi or mpich. Attempting to compile without MPI support.")
    mpi_build_args = []
    mpi_link_args = []

extension = Extension(
    "*",
    ["pdc/*.pyx"],
    libraries=["pdc"],
    library_dirs=[os.path.join(PDC_DIR, "install", "lib")],
    include_dirs=[
        os.path.join(PDC_DIR, "install", "include"),
        os.path.join(MERCURY_DIR, "include"),
        os.path.join(PDC_DIR, "utils", "include"), #for pdc_id_pkg.h
        os.path.join(PDC_DIR, "api", "pdc_obj", "include") #for pdc_(obj/cont/prop)_pkg.h
    ],
    extra_compile_args=mpi_build_args,
    extra_link_args=mpi_link_args
)

#extension.cython_directives = {'language_level': "3"}

version_file = open('version.txt', 'r')
version = version_file.read().strip()
version_file.close()

setup(
    name='PDCpy',
    version=version,
    include_package_data=True,
    ext_modules=cythonize(extension, language_level=3),
    zip_safe=False,
)
