import pdc
import pytest
from time import sleep
import sys

capture = True

with pdc.ServerContext():
    pdc.init()
    pytest.main((['tests/'] if capture else ['-s', 'tests/']) if len(sys.argv) == 1 else ([] if capture else ['-s']) + sys.argv[1:])