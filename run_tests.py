import pdc
import pytest
from time import sleep

with pdc.ServerContext():
    sleep(0.5)
    #TODO: find better way to await server ready
    pdc.init()
    pytest.main(['tests/'])