import pdc

def test_make_container():
    #make a container.  The container is persistent by default.
    cont = pdc.Container('persistent_cont')

    #make a transient container, it will be deleted when the pdc server is closed
    cont2 = pdc.Container('transient_cont', lifetime=pdc.Container.Lifetime.TRANSIENT)

    assert cont.lifetime == pdc.Container.Lifetime.PERSISTENT
    assert cont2.lifetime == pdc.Container.Lifetime.TRANSIENT