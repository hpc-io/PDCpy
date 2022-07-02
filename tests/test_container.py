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
    assert cont.lifetime == Container.Lifetime.TRANSIENT

    cont.persist()
    assert cont.lifetime == Container.Lifetime.PERSISTENT

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
