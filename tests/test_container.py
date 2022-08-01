import pytest
import pdc
from pdc import Container, PDCError

def test_container_name():
    cont = pdc.Container('contnametest')
    assert cont.name == 'contnametest'

    #https://github.com/hpc-io/pdc/issues/64
    #with pytest.raises(PDCError):
    #    cont2 = pdc.Container('contnametest')

    #unicode:
    cont2 = pdc.Container('∁∂∃_∄∅d∆∇')
    assert cont2.name == '∁∂∃_∄∅d∆∇'

    with pytest.raises(TypeError):
        cont3 = pdc.Container(1)

def test_container_lifetime():
    cont = pdc.Container('contlifetest')
    assert cont.lifetime == pdc.Container.Lifetime.TRANSIENT

    cont.persist()
    assert cont.lifetime == pdc.Container.Lifetime.PERSISTENT

    cont2 = pdc.Container('contlifetest2', lifetime=Container.Lifetime.PERSISTENT)
    assert cont2.lifetime == Container.Lifetime.PERSISTENT

    with pytest.raises(TypeError):
        cont3 = pdc.Container('contlifetest3', lifetime=1)
    

def test_container_get_del():
    cont = pdc.Container('contgetdel')
    contref = Container.get('contgetdel')
    assert contref.name == 'contgetdel'

    #cont2 = pdc.Container('contgetdel2')
    #cont2.delete()
    #with pytest.raises(PDCError):
    #    cont2ref = Container.get('contgetdel2')
    
    #cont2 = pdc.Container('contgetdel2')

@pytest.mark.skip
#this has no tests on the c side
def test_put_del_ids():
    cont = pdc.Container('contputdelids', lifetime=pdc.Container.Lifetime.TRANSIENT)
    cont2 = pdc.Container('contputdelids2', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(dims=(8, 6), type=pdc.Type.INT16)
    obj = pdc.Object('objputdelids', prop, cont, lifetime=pdc.Container.Lifetime.TRANSIENT)
    obj2 = pdc.Object('objputdelids2', prop, cont, lifetime=pdc.Container.Lifetime.TRANSIENT)
    obj3 = pdc.Object('objputdelids3', prop, cont, lifetime=pdc.Container.Lifetime.TRANSIENT)

    cont.remove_objects([obj, obj2, obj3])
    cont2.add_objects([obj, obj2, obj3])

    cont2.remove_objects(obj2)
    cont2.add_objects(obj2)

    with pytest.raises(TypeError):
        cont2.remove_objects(1)
    
    with pytest.raises(TypeError):
        cont2.add_objects(1)