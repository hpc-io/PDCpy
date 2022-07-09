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

mpi_build_args = os.popen('mpicc -compile_info').read().strip().split()[1:]
mpi_link_args = os.popen('mpicc -link_info').read().strip().split()[1:]

setup(
    name='Proactive Data Containers',
    ext_modules=cythonize(Extension("*", ["pdc/*.pyx"],
        libraries=["pdc"], 
        library_dirs=[os.path.join(PDC_DIR, "install", "bin")],
        include_dirs=[os.path.join(PDC_DIR, "api"), os.path.join(PDC_DIR, "install", "api"), #install folder is needed because that's where pdc_config.h is placed
            os.path.join(MERCURY_DIR, "include")],
        extra_compile_args=mpi_build_args,
        extra_link_args=mpi_link_args
    ), language_level='3str', gdb_debug=True),
    zip_safe=False,
)
