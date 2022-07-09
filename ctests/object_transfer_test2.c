/*
init(PDC) -> 36028797018963968
prop_create(PDC_CONT_CREATE, 36028797018963968) -> 72057594037927936
prop_set_cont_lifetime(72057594037927936, Lifetime.TRANSIENT) -> 0
cont_create(b'test_transfer_color_by_number', 72057594037927936) -> 144115188075855872
prop_close(72057594037927936) -> 0
prop_create(PDC_OBJ_CREATE, 36028797018963968) -> 108086391056891904
prop_set_obj_dims(108086391056891904, 2, (8, 8)) -> 0
prop_set_obj_type(108086391056891904, Type.INT8) -> 0
prop_set_obj_time_step(108086391056891904, 0) -> 0
prop_set_obj_user_id(108086391056891904, 1000) -> 0
obj_create(144115188075855872, b'colorbynumobj', 108086391056891904) -> 180143985094819840
region_create(2, (0, 0), (8, 8)) -> 216172782113783808
region_create(2, (0, 0), (8, 8)) -> 216172782113783809
region_transfer_create([[0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]], RequestType.SET, 180143985094819840, 216172782113783809, 216172782113783808) -> 252201579132747776
region_transfer_start(252201579132747776) -> ?
region_transfer_start(252201579132747776) -> 0
region_transfer_wait(252201579132747776) -> ?
region_transfer_wait(252201579132747776) -> 0
region_close(216172782113783809) -> 0
region_close(216172782113783808) -> 0
region_transfer_close(252201579132747776) -> 0
region_create(2, (0, 0), (2, 8)) -> 216172782113783810
region_create(2, (0, 0), (2, 8)) -> 216172782113783811
region_transfer_create([[1 1 1 1 1 1 1 1]
 [1 1 1 1 1 1 1 1]], RequestType.SET, 180143985094819840, 216172782113783811, 216172782113783810) -> 252201579132747777
region_transfer_start(252201579132747777) -> ?
region_transfer_start(252201579132747777) -> 0
region_create(2, (2, 1), (6, 2)) -> 216172782113783812
region_create(2, (0, 0), (6, 2)) -> 216172782113783813
region_transfer_create([[2 2]
 [2 2]
 [2 2]
 [2 2]
 [2 2]
 [2 2]], RequestType.SET, 180143985094819840, 216172782113783813, 216172782113783812) -> 252201579132747778
region_transfer_start(252201579132747778) -> ?
region_transfer_start(252201579132747778) -> 0
region_transfer_wait(252201579132747777) -> ?
region_transfer_wait(252201579132747777) -> 0
region_transfer_wait(252201579132747778) -> ?
region_transfer_wait(252201579132747778) -> 0
region_create(2, (0, 0), (8, 8)) -> 216172782113783814
region_create(2, (0, 0), (8, 8)) -> 216172782113783815
region_transfer_create([[0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]
 [0 0 0 0 0 0 0 0]], RequestType.GET, 180143985094819840, 216172782113783815, 216172782113783814) -> 252201579132747779
region_transfer_start(252201579132747779) -> ?
region_transfer_start(252201579132747779) -> 0
region_transfer_wait(252201579132747779) -> ?
region_transfer_wait(252201579132747779) -> 0
region_close(216172782113783815) -> 0
region_close(216172782113783814) -> 0
region_transfer_close(252201579132747779) -> 0
region_close(216172782113783813) -> 0
region_close(216172782113783812) -> 0
region_transfer_close(252201579132747778) -> 0
region_close(216172782113783811) -> 0
region_close(216172782113783810) -> 0
region_transfer_close(252201579132747777) -> 0
obj_close(180143985094819840) -> 0
prop_close(108086391056891904) -> 0
cont_close(144115188075855872) -> 0
close(36028797018963968) -> 0
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdc.h"

int main(int argc, char **argv) {
    // init(PDC) -> 36028797018963968
    pdcid_t pdcid = PDCinit("PDC");

    // prop_create(PDC_CONT_CREATE, 36028797018963968) -> 72057594037927936
    pdcid_t cont_prop = PDCprop_create(PDC_CONT_CREATE, pdcid);

    // prop_set_cont_lifetime(72057594037927936, Lifetime.TRANSIENT) -> 0
    PDCprop_set_cont_lifetime(cont_prop, PDC_TRANSIENT);

    // cont_create(b'test_transfer_color_by_number', 72057594037927936) -> 144115188075855872
    pdcid_t cont_id = PDCcont_create("test_transfer_color_by_number", cont_prop);

    // prop_close(72057594037927936) -> 0
    PDCprop_close(cont_prop);

    // prop_create(PDC_OBJ_CREATE, 36028797018963968) -> 108086391056891904
    pdcid_t obj_prop = PDCprop_create(PDC_OBJ_CREATE, pdcid);

    // prop_set_obj_dims(108086391056891904, 2, (8, 8)) -> 0
    uint64_t dims[2] = {8, 8};
    PDCprop_set_obj_dims(obj_prop, 2, dims);

    // prop_set_obj_type(108086391056891904, Type.INT8) -> 0
    PDCprop_set_obj_type(obj_prop, PDC_INT8);

    // prop_set_obj_time_step(108086391056891904, 0) -> 0
    PDCprop_set_obj_time_step(obj_prop, 0);

    // prop_set_obj_user_id(108086391056891904, 1000) -> 0
    PDCprop_set_obj_user_id(obj_prop, 1000);

    // obj_create(144115188075855872, b'colorbynumobj', 108086391056891904) -> 180143985094819840
    pdcid_t obj_id = PDCobj_create(cont_id, "colorbynumobj", obj_prop);

    // region_create(2, (0, 0), (8, 8)) -> 216172782113783808
    uint64_t offset[2] = {0, 0};
    uint64_t size[2] = {8, 8};
    pdcid_t region_id = PDCregion_create(2, offset, size);

    // region_create(2, (0, 0), (8, 8)) -> 216172782113783809
    pdcid_t region_id2 = PDCregion_create(2, offset, size);

    // region_transfer_create([[0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]], RequestType.SET, 180143985094819840, 216172782113783809, 216172782113783808) -> 252201579132747776
    uint8_t data[8][8];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            data[i][j] = 0;
        }
    }
    pdcid_t transfer_id = PDCregion_transfer_create(data, PDC_WRITE, obj_id, region_id2, region_id);

    // region_transfer_start(252201579132747776) -> 0
    PDCregion_transfer_start(transfer_id);

    // region_transfer_wait(252201579132747776) -> 0
    PDCregion_transfer_wait(transfer_id);

    // region_close(216172782113783809) -> 0
    PDCregion_close(region_id);

    // region_close(216172782113783808) -> 0
    PDCregion_close(region_id2);

    // region_transfer_close(252201579132747776) -> 0
    PDCregion_transfer_close(transfer_id);

    // region_create(2, (0, 0), (2, 8)) -> 216172782113783810
    offset[0] = 0;
    offset[1] = 0;
    size[0] = 2;
    size[1] = 8;
    region_id = PDCregion_create(2, offset, size);

    // region_create(2, (0, 0), (2, 8)) -> 216172782113783811
    region_id2 = PDCregion_create(2, offset, size);

    // region_transfer_create([[1 1 1 1 1 1 1 1]
    // [1 1 1 1 1 1 1 1]], RequestType.SET, 180143985094819840, 216172782113783811, 216172782113783810) -> 252201579132747777
    uint8_t data2[2][8];
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 8; j++) {
            data2[i][j] = 1;
        }
    } 
    transfer_id = PDCregion_transfer_create(data2, PDC_WRITE, obj_id, region_id2, region_id);

    // region_transfer_start(252201579132747777) -> 0
    PDCregion_transfer_start(transfer_id);

    // region_create(2, (2, 1), (6, 2)) -> 216172782113783812
    offset[0] = 2;
    offset[1] = 1;
    offset[0] = 6;
    offset[1] = 2;
    pdcid_t region_id3 = PDCregion_create(2, offset, size);

    // region_create(2, (0, 0), (6, 2)) -> 216172782113783813
    offset[0] = 0;
    offset[1] = 0;
    pdcid_t region_id4 = PDCregion_create(2, offset, size);

    // region_transfer_create([[2 2]
    // [2 2]
    // [2 2]
    // [2 2]
    // [2 2]
    // [2 2]], RequestType.SET, 180143985094819840, 216172782113783813, 216172782113783812) -> 252201579132747778
    uint8_t data3[6][2];
    for (int i = 0; i < 6; i++) {
        for (int j = 0; j < 2; j++) {
            data3[i][j] = 2;
        }
    }
    pdcid_t transfer_id2 = PDCregion_transfer_create(data3, PDC_WRITE, obj_id, region_id4, region_id3);

    // region_transfer_start(252201579132747778) -> 0
    PDCregion_transfer_start(transfer_id2);

    // region_transfer_wait(252201579132747777) -> 0
    PDCregion_transfer_wait(transfer_id);

    // region_transfer_wait(252201579132747778) -> 0
    PDCregion_transfer_wait(transfer_id2);

    // region_create(2, (0, 0), (8, 8)) -> 216172782113783814
    offset[0] = 0;
    offset[1] = 0;
    size[0] = 8;
    size[1] = 8;
    pdcid_t region_id5 = PDCregion_create(2, offset, size);

    // region_create(2, (0, 0), (8, 8)) -> 216172782113783815
    pdcid_t region_id6 = PDCregion_create(2, offset, size);
    
    // region_transfer_create([[0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]
    // [0 0 0 0 0 0 0 0]], RequestType.GET, 180143985094819840, 216172782113783815, 216172782113783814) -> 252201579132747779
    uint8_t data_out[8][8];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            data_out[i][j] = 0;
        }
    }
    //puts("TEST");
    pdcid_t transfer_id3 = PDCregion_transfer_create(data_out, PDC_READ, obj_id, region_id6, region_id5);
    //puts("TEST2");

    // region_transfer_start(252201579132747779) -> 0
    PDCregion_transfer_start(transfer_id3);

    // region_transfer_wait(252201579132747779) -> 0
    PDCregion_transfer_wait(transfer_id3);

    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++)
            printf("%d\t", data_out[i][j]);
        printf("\n");
    }

    // region_close(216172782113783815) -> 0
    PDCregion_close(region_id6);

    // region_close(216172782113783814) -> 0
    PDCregion_close(region_id5);

    // region_transfer_close(252201579132747779) -> 0
    PDCregion_transfer_close(transfer_id3);

    // region_close(216172782113783813) -> 0
    PDCregion_close(region_id4);

    // region_close(216172782113783812) -> 0
    PDCregion_close(region_id3);

    // region_transfer_close(252201579132747778) -> 0
    PDCregion_transfer_close(transfer_id2);

    // region_close(216172782113783811) -> 0
    PDCregion_close(region_id2);

    // region_close(216172782113783810) -> 0
    PDCregion_close(region_id);

    // region_transfer_close(252201579132747777) -> 0
    PDCregion_transfer_close(transfer_id);

    // obj_close(180143985094819840) -> 0
    PDCobj_close(obj_id);

    // prop_close(108086391056891904) -> 0
    PDCprop_close(obj_prop);

    // cont_close(144115188075855872) -> 0
    PDCcont_close(cont_id);

    // close(36028797018963968) -> 0
    PDCclose(pdcid);
}
