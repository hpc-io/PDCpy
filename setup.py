from setuptools import Extension, setup
from Cython.Build import cythonize
import os
import sys

def get_env_or_exit(name):
    try:
        value = os.environ[name]
    except KeyError:
        sys.exit(f'Environment variable {name} not set. Aborting')
    return value


PDC_DIR = os.path.join(*os.path.split(get_env_or_exit("PDC_DIR"))[:-1])
MERCURY_DIR = get_env_or_exit("MERCURY_DIR")
print(MERCURY_DIR)

setup(
    name='Proactive Data Containers',
    ext_modules=cythonize([Extension("pdc", ["pdc.pyx"], libraries=["pdc"], 
            library_dirs=[os.path.join(PDC_DIR, "install", "bin")],
            include_dirs=[os.path.join(PDC_DIR, "api"), os.path.join(PDC_DIR, "install", "api"), #install folder is needed because that's where pdc_config.h is placed
                          os.path.join(MERCURY_DIR, "include")])], 
            language_level='3'),
    zip_safe=False,
)
