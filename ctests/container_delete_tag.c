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
    // create a container
    cont_id = PDCcont_create("cont", cont_prop);
    if (cont_id <= 0)
        printf("Fail to create container @ line  %d!\n", __LINE__);

    //put tag
    if (PDCcont_put_tag(cont_id, "a", "b", 1) != 0)
        printf("Fail to put tag @ line  %d!\n", __LINE__);

    //delete tag
    PDCcont_del_tag(cont_id, "a"); //SEGFAULT HERE

    PDCcont_close(cont_id);
    
    PDCclose(pdc_id);
    
#ifdef ENABLE_MPI
    MPI_Finalize();
#endif
    return ret_value;
}
