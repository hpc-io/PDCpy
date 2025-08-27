import pdc
import pytest
from pdc import KVTags

def test_encode():
    assert KVTags._encode('test') == b"'test'"
    assert KVTags._encode('∁∂∃∄∅∆∇') == '\'∁∂∃∄∅∆∇\''.encode('utf-8')
    assert KVTags._encode(3) == b'3'
    assert KVTags._encode(3.2) == b'3.2'
    # assert KVTags._encode(()) == b'()'
    assert KVTags._encode((1, 2, 3)) == b'(1,2,3)'
    # assert KVTags._encode(((), (2.2, 'merp'), (-55, True))) == b"((),(2.2,'merp'),(-55,True))"
    assert KVTags._encode((False, True, False)) == b'(False,True,False)'

    # with pytest.raises(TypeError):
    #     KVTags._encode({})
    # 
    # with pytest.raises(TypeError):
    #     KVTags._encode([])
    # 
    # with pytest.raises(TypeError):
    #     KVTags._encode(b'hi')

def test_decode():
    assert KVTags._decode(b"'test'") == 'test'
    assert KVTags._decode('\'∁∂∃∄∅∆∇\''.encode('utf-8')) == '∁∂∃∄∅∆∇'
    assert KVTags._decode(b'3') == 3
    assert KVTags._decode(b'3.2') == 3.2
    # assert KVTags._decode(b'()') == ()
    assert KVTags._decode(b'(1,2,3)') == (1, 2, 3)
    # assert KVTags._decode(b"((),(2.2,'merp'),(-55,True))") == ((), (2.2, 'merp'), (-55, True))
    assert KVTags._decode(b'(False,True,False)') == (False, True, False)

def test_object_tags():
    cont = pdc.Container('testobjkvtags', lifetime=pdc.Container.Lifetime.TRANSIENT)
    prop = pdc.Object.Properties(dims=(3, 4, 5), type=pdc.Type.FLOAT)
    obj = cont.create_object('testobjkvtags', prop)

    obj.tags['merp'] = 'derp'
    obj.tags['derp'] = (1, 2, 3, None, True, False, 3.6332)
    assert obj.tags['merp'] == 'derp'
    assert obj.tags['derp'] == (1, 2, 3, None, True, False, 3.6332)

    del obj.tags['merp']
    del obj.tags['derp']

def test_container_tags():
    cont = pdc.Container('testcontkvtags', lifetime=pdc.Container.Lifetime.TRANSIENT)
    
    cont.tags['a'] = 'b'
    cont.tags['b'] = (True, False, -44.88, (None,), 'merp')

    assert cont.tags['a'] == 'b'
    assert cont.tags['b'] == (True, False, -44.88, (None,), 'merp')

    #https://github.com/hpc-io/pdc/issues/66
    with pytest.raises(NotImplementedError):
        del cont.tags['a']
