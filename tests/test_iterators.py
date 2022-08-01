import pdc

def test_object_iter():
    cont = pdc.Container('test_container_iter', lifetime=pdc.Container.Lifetime.TRANSIENT)
    assert list(cont.all_local_objects()) == []

    prop = pdc.Object.Properties(dims=(8, 6), type=pdc.Type.INT16)
    obj = pdc.Object('test_container_iter_obj', prop, cont)
    obj2 = pdc.Object('test_container_iter_obj2', prop, cont)
    obj3 = pdc.Object('test_container_iter_obj3', prop, cont)

    obj_set = set((obj, obj2, obj3))
    count = 0
    for obj in cont.all_local_objects():
        assert obj in obj_set
        count += 1
    
    assert count == 3

def test_container_iter():
    assert list(pdc.all_local_containers()) == []

    cont = pdc.Container('test_container_iter', lifetime=pdc.Container.Lifetime.TRANSIENT)
    cont2 = pdc.Container('test_container_iter2', lifetime=pdc.Container.Lifetime.TRANSIENT)
    cont3 = pdc.Container('test_container_iter3', lifetime=pdc.Container.Lifetime.TRANSIENT)

    cont_set = set((cont, cont2, cont3))
    count = 0
    for cont in pdc.all_local_containers():
        assert cont in cont_set
        count += 1
    
    assert count == 3
