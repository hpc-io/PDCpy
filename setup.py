from distutils import extension
from setuptools import Extension, setup
from Cython.Build import cythonize
import os
import sys

def get_env_or_exit(name):
    try:
        value = os.environ[name]
    except KeyError:
        sys.exit('Environment variable %s not set. Aborting' % name)
    return value


PDC_DIR = os.path.join(*os.path.split(get_env_or_exit("PDC_DIR"))[:-1])
MERCURY_DIR = get_env_or_exit("MERCURY_DIR")

#TODO: use MPICC environment variable to let user choose compiler
mpi_build_args = os.popen('mpicc -compile_info').read().strip().split()[1:]
mpi_link_args = os.popen('mpicc -link_info').read().strip().split()[1:]

#print(mpi_build_args)
#print(mpi_link_args)

setup(
    name='Proactive Data Containers',
    ext_modules=cythonize(
        Extension(
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
        ),
    language_level='3str'),
    zip_safe=False,
)
