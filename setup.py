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

# Removed [-1] from the end
PDC_DIR = os.path.join(*os.path.split(get_env_or_exit("PDC_DIR")))
MERCURY_DIR = get_env_or_exit("MERCURY_DIR")

path = shutil.which('mpicc')
if not path:
    print("mpicc not found on PATH. Attempting to compile without MPI support.")
    mpi_build_args = []
    mpi_link_args = []
else:
    # Try OpenMPI style first
    try:
        compile_output = subprocess.check_output(['mpicc', '--showme:compile'], stderr=subprocess.PIPE, text=True)
        link_output = subprocess.check_output(['mpicc', '--showme:link'], stderr=subprocess.PIPE, text=True)
        print("Compiling with openmpi")
        mpi_build_args = compile_output.strip().split()
        mpi_link_args = link_output.strip().split()
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Try MPICH style
        try:
            compile_output = subprocess.check_output(['mpicc', '-compile_info'], stderr=subprocess.PIPE, text=True)
            link_output = subprocess.check_output(['mpicc', '-link_info'], stderr=subprocess.PIPE, text=True)
            print("Compiling with mpich")
            mpi_build_args = [arg for arg in compile_output.strip().split() if arg != '-compile_info']
            mpi_link_args = [arg for arg in link_output.strip().split() if arg != '-link_info']
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("mpicc is neither openmpi or mpich. Attempting to compile without MPI support.")
            mpi_build_args = []
            mpi_link_args = []

# Removed "install"
extension = Extension(
    "*",
    ["pdc/*.pyx"],
    libraries=["pdc"],
    library_dirs=[os.path.join(PDC_DIR, "lib")],
    include_dirs=[
        os.path.join(PDC_DIR, "include"),
        os.path.join(MERCURY_DIR, "include"),
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
    ext_modules=cythonize(extension, language_level=3),
    zip_safe=False,
)
