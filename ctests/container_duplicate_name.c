#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdc.h"

int
main(int argc, char **argv)
{
    pdcid_t pdc_id, cont_id, cont_prop, cont_id2;
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
    cont_id = PDCcont_create("VPIC_cont", cont_prop);
    if (cont_id <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);
    
    cont_id2 = PDCcont_create("VPIC_cont", cont_prop);
    if (cont_id2 <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);
    
    PDCclose(pdc_id);
    
#ifdef ENABLE_MPI
    MPI_Finalize();
#endif
    return ret_value;
}
