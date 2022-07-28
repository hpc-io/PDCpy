import numpy as np
import pdc
from datetime import time
import pytest

def test_build_query():
    cont = pdc.Container('buildquerycont')
    prop = pdc.Object.Properties(dims = 10, type = pdc.Type.INT16)
    obj = pdc.Object('buildqueryobj', prop, cont)
    
    def objs():
        x = 0
        while True:
            yield pdc.Object(f'buildqueryobj{x}', prop, cont)
            x += 1
    
    it = iter(objs())
    def nextobj():
        return next(it)

    query = nextobj().data > 45
    query2 = nextobj().data < 45
    query3 = nextobj().data == 45
    query5 = nextobj().data >= 45
    query6 = nextobj().data <= 45

    query7 = query & query2
    query8 = query | query2
    query9 = (query3 & query8) | (query7 & query5) | (query & query6)

LENGTH = 100_000_000

@pytest.mark.skip
def test_big_query():
    cont = pdc.Container()
    prop = pdc.Object.Properties(
        LENGTH,
        pdc.Type.INT64,
        time_step = 0,
        app_name = 'DataServerTest'
    )
    obj = pdc.Object('bigqueryobj', prop, cont)
    start = time.time()
    data = np.fromiter(range(0, LENGTH), dtype=np.int64)
    
    obj.set_data(data)

    end = time.time()
    print(f'Set data in {end - start} seconds')

    query = ((obj.data < 1000) | (obj.data >= 2000 & obj.data < 3000) | (obj.data >= 5000 & obj.data < 7000))
    print(query.get_result()[obj])