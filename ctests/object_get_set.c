#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdc.h"

int
main(int argc, char **argv)
{
    pdcid_t pdc_id, cont_id, cont_prop, cont_id2, obj_prop, obj_id, global_region_id, transfer_id, local_region_id;
    int     rank = 0, size = 1;
    int     ret_value = 0;

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
    cont_id = PDCcont_create("cont", cont_prop);
    if (cont_id <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);
    
    //create object and object properties
    obj_prop = PDCprop_create(PDC_OBJ_CREATE, pdc_id);
    if (obj_prop <= 0)
        printf("Fail to create object property @ line  %d!\n", __LINE__);
    uint64_t dims[] = {8, 8};
    if (PDCprop_set_obj_dims(obj_prop, 2, dims) != 0)
        printf("Fail to set object dimensions @ line  %d!\n", __LINE__);
    if (PDCprop_set_obj_type(obj_prop, PDC_INT8) != 0)
        printf("Fail to set object type @ line  %d!\n", __LINE__);
    obj_id = PDCobj_create(cont_id, "obj", obj_prop);
    if (obj_id <= 0)
        printf("Fail to create object @ line  %d!\n", __LINE__);
    
    //set all elements to 1
    uint8_t *data = (uint8_t *)malloc(64);
    for (int i = 0; i < 64; i++)
        data[i] = 1;
    if (PDCobj_put_data(obj_id, global_region_id, data) != 0) {
        printf("Fail to put data @ line  %d!\n", __LINE__);
        ret_value = 1;
    }
}