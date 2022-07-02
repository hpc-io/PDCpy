import pdc
import pytest
from time import sleep
import sys

with pdc.ServerContext():
    pdc.init()
    pytest.main(['tests/', *sys.argv[1:]])