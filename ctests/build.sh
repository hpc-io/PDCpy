set -e

mpicc ./query.c -o query.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
mpicc ./container_duplicate_name.c -o container_duplicate_name.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
mpicc ./container_get_after_delete.c -o container_get_after_delete.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
mpicc ./obj_set_all_data.c -o obj_set_all_data.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
mpicc ./container_delete_tag.c -o container_delete_tag.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
mpicc ./object_transfer_test2.c -o object_transfer_test2.out -lpdc -I/home/gerzytet/Documents/PDC/mercury/pdc/src/api -I$PDC_DIR/include -L$PDC_DIR/lib
