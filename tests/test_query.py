import numpy as np
import pdc
import pdc.main
import time
import pytest

def test_build_query():
    cont = pdc.Container('buildquerycont', lifetime=pdc.Container.Lifetime.TRANSIENT)
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

    assert len(query9.objects) == 5

LENGTH = 3_000_000

#TODO: think about this: closing an object without waiting on its open requests is a segfault
def test_big_query():
    cont = pdc.Container(f'bigquerycont{LENGTH}', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(
        LENGTH,
        pdc.Type.INT64
    )
    obj = pdc.Object(f'bigqueryobj{LENGTH}', prop, cont)
    data = np.fromiter(range(0, LENGTH), dtype=np.int64)
    start = time.time()
    obj.set_data(data).wait_for_result()

    end = time.time()
    print(f'Set {LENGTH//1_000_000} data in {end - start} seconds')

    query = ((obj.data < 1000) | ((obj.data >= 2000) & (obj.data < 3000)) | ((obj.data >= 5000) & (obj.data < 7000)))
    #result = query.get_result()[obj]

@pytest.mark.skip
def test_queries():
    cont  = pdc.Container('queriescont', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(dims = 16, type = pdc.Type.INT16)
    obj = pdc.Object('queriesobj', prop, cont)

    obj.set_data(range(16)).wait_for_result()
    #print(obj.get_data().wait_for_result())
    #print(obj.get_data().wait_for_result())
    assert (obj.data >= 8).get_result().hits == 8