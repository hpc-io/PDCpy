#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdc.h"

int
main(int argc, char **argv)
{
    // create a pdc
#ifdef ENABLE_MPI
    MPI_Init(&argc, &argv);
#endif

    //init(PDC) -> 36028797018963968
    pdcid_t pdc_id = PDCinit("pdc");

    //prop_create(PDC_CONT_CREATE, 36028797018963968) -> 72057594037927936
    pdcid_t cont_prop = PDCprop_create(PDC_CONT_CREATE, pdc_id);

    //prop_set_cont_lifetime(72057594037927936, Lifetime.TRANSIENT) -> 0
    PDCprop_set_cont_lifetime(cont_prop, PDC_TRANSIENT);
    
    //cont_create(b'queriescont', 72057594037927936) -> 144115188075855872
    pdcid_t cont_id = PDCcont_create("cont", cont_prop);
    if (cont_id <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);

    //prop_close(72057594037927936) -> 0
    PDCprop_close(cont_prop);

    //prop_create(PDC_OBJ_CREATE, 36028797018963968) -> 108086391056891904
    pdcid_t obj_prop = PDCprop_create(PDC_OBJ_CREATE, pdc_id);

    //prop_set_obj_dims(108086391056891904, 1, (16,)) -> 0
    uint64_t dims[] = {16};
    if (PDCprop_set_obj_dims(obj_prop, 1, dims) != 0)
        printf("Fail to set object dimensions @ line  %d!\n", __LINE__);
    
    //prop_set_obj_type(108086391056891904, Type.INT16) -> 0
    if (PDCprop_set_obj_type(obj_prop, PDC_INT16) != 0)
        printf("Fail to set object type @ line  %d!\n", __LINE__);
    
    //prop_set_obj_time_step(108086391056891904, 0) -> 0
    if (PDCprop_set_obj_time_step(obj_prop, 0) != 0)
        printf("Fail to set object time step @ line  %d!\n", __LINE__);
    
    //prop_set_obj_user_id(108086391056891904, 1000) -> 0
    if (PDCprop_set_obj_user_id(obj_prop, 1000) != 0)
        printf("Fail to set object user id @ line  %d!\n", __LINE__);

    //obj_create(144115188075855872, b'queriesobj', 108086391056891904) -> 180143985094819840
    pdcid_t obj_id = PDCobj_create(cont_id, "obj", obj_prop);

    //region_create(1, (0,), (16,)) -> 216172782113783808
    uint64_t offset[] = {0};
    uint64_t size[] = {16};
    pdcid_t region_id = PDCregion_create(1, offset, size);

    //region_create(1, (0,), (16,)) -> 216172782113783809
    pdcid_t region_id2 = PDCregion_create(1, offset, size);

    //region_transfer_create([ 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15], RequestType.SET, 180143985094819840, 216172782113783809, 216172782113783808) -> 252201579132747776
    int16_t data[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    pdcid_t region_transfer_id = PDCregion_transfer_create(data, PDC_WRITE, obj_id, region_id2, region_id);

    //region_transfer_start(252201579132747776) -> 0
    if (PDCregion_transfer_start(region_transfer_id) != 0)
        printf("Fail to start region transfer @ line  %d!\n", __LINE__);
    
    //region_transfer_wait(252201579132747776) -> 0
    if (PDCregion_transfer_wait(region_transfer_id) != 0)
        printf("Fail to wait region transfer @ line  %d!\n", __LINE__);
    
    //region_close(216172782113783809) -> 0
    if (PDCregion_close(region_id2) != 0)
        printf("Fail to close region @ line  %d!\n", __LINE__);
    
    //region_close(216172782113783808) -> 0
    if (PDCregion_close(region_id) != 0)
        printf("Fail to close region @ line  %d!\n", __LINE__);
    
    //region_transfer_close(252201579132747776) -> 0
    if (PDCregion_transfer_close(region_transfer_id) != 0)
        printf("Fail to close region transfer @ line  %d!\n", __LINE__);
    
    //query_create(180143985094819840, GTE, INT16, 8) -> 28512112
    int16_t bound = 8;
    pdc_query_t *query_id = PDCquery_create(obj_id, PDC_GTE, PDC_INT16, &bound);

    //query_get_selection(28512112, 140421247985296) -> 0
    pdc_selection_t *selection = (pdc_selection_t *)malloc(sizeof(pdc_selection_t));
    if (PDCquery_get_selection(query_id, selection) != 0)
        printf("Fail to get query selection @ line  %d!\n", __LINE__);
    
    printf("hits: %ld\n", selection->nhits);
    
    //selection_free(140421247985296) -> None
    PDCselection_free(selection);

    //query_free(28512112) -> None
    PDCquery_free(query_id);

    //obj_close(180143985094819840) -> 0
    if (PDCobj_close(obj_id) != 0)
        printf("Fail to close object @ line  %d!\n", __LINE__);
    
    //prop_close(108086391056891904) -> 0
    if (PDCprop_close(obj_prop) != 0)
        printf("Fail to close property @ line  %d!\n", __LINE__);
    
    //cont_close(144115188075855872) -> 0
    if (PDCcont_close(cont_id) != 0)
        printf("Fail to close container @ line  %d!\n", __LINE__);
    
    //close(36028797018963968) -> 0
    if (PDCclose(pdc_id) != 0)
        printf("Fail to close PDC @ line  %d!\n", __LINE__);
    
    #ifdef ENABLE_MPI
    MPI_Finalize();
    #endif
    
    return 0;
}