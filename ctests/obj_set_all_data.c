#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdc.h"

int
main(int argc, char **argv)
{
    pdcid_t pdc_id, cont_id, cont_prop, cont_id2, obj_prop, obj_id, region_id, transfer_id;
    int     rank = 0, size = 1;
    int     ret_value = 0;
    double  *data = (double *) malloc(sizeof(double) * 128);

    // create a pdc
#ifdef ENABLE_MPI
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
#endif

    pdc_id = PDCinit("pdc");
    cont_prop = PDCprop_create(PDC_CONT_CREATE, pdc_id);
    if (cont_prop <= 0)
        printf("Fail to create container property @ line  %d!\n", __LINE__);

    // create a container
    cont_id = PDCcont_create("VPIC_cont", cont_prop);
    if (cont_id <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);
    
    //create object and object properties
    obj_prop = PDCprop_create(PDC_OBJ_CREATE, pdc_id);
    if (obj_prop <= 0)
        printf("Fail to create object property @ line  %d!\n", __LINE__);
    uint64_t dims[] = {128};
    if (PDCprop_set_obj_dims(obj_prop, 1, dims) != 0)
        printf("Fail to set object dimensions @ line  %d!\n", __LINE__);
    if (PDCprop_set_obj_type(obj_prop, PDC_DOUBLE) != 0)
        printf("Fail to set object type @ line  %d!\n", __LINE__);
    obj_id = PDCobj_create(cont_id, "obj", obj_prop);
    if (obj_id <= 0)
        printf("Fail to create object @ line  %d!\n", __LINE__);

    uint64_t offsets[] = {0};

    //create region.  this region will be used for all region parameters.
    region_id = PDCregion_create(1, offsets, dims);
    if (region_id <= 0)
        printf("Fail to create region @ line  %d!\n", __LINE__);
    
    //set object data.
    memset(data, 1.0, 128 * sizeof(double));
    transfer_id = PDCregion_transfer_create(data, PDC_WRITE, obj_id, region_id, region_id);
    if (transfer_id <= 0)
        printf("Fail to create transfer @ line  %d!\n", __LINE__);
    if (PDCregion_transfer_start(transfer_id) != SUCCEED)
        printf("Fail to start transfer @ line  %d!\n", __LINE__);
    if (PDCregion_transfer_wait(transfer_id) != SUCCEED)
        printf("Fail to wait transfer @ line  %d!\n", __LINE__);
    
    PDCregion_close(region_id);

    puts("here");
    
    //create output buffer for getting data
    double *data_out = (double *) malloc(sizeof(double) * 128);
    transfer_id = PDCregion_transfer_create(data_out, PDC_READ, obj_id, region_id, region_id);  //SEGFAULT HERE
    if (transfer_id <= 0)
        printf("Fail to create transfer @ line  %d!\n", __LINE__);
    puts("here");
    if (PDCregion_transfer_start(transfer_id) != SUCCEED)
        printf("Fail to start transfer @ line  %d!\n", __LINE__);
    puts("here");
    if (PDCregion_transfer_wait(transfer_id) != SUCCEED)
        printf("Fail to wait transfer @ line  %d!\n", __LINE__);
    
    for (int i = 0; i < 128; i++)
        if (data[i] != data_out[i])
            printf("Wrong data value @ line  %d!\n", __LINE__);
    
    if (PDCregion_close(region_id) != SUCCEED)
        printf("Fail to close region @ line  %d!\n", __LINE__);
    if (PDCregion_transfer_close(transfer_id) != SUCCEED)
        printf("Fail to close transfer @ line  %d!\n", __LINE__);
    if (PDCobj_close(obj_id) != SUCCEED)
        printf("Fail to close object @ line  %d!\n", __LINE__);
    if (PDCprop_close(obj_prop) != SUCCEED)
        printf("Fail to close object property @ line  %d!\n", __LINE__);
    if (PDCcont_close(cont_id) != SUCCEED)
        printf("Fail to close container @ line  %d!\n", __LINE__);
    
    PDCclose(pdc_id);
    
#ifdef ENABLE_MPI
    MPI_Finalize();
#endif
    return ret_value;
}
