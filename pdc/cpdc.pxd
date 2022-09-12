from libc.stdint cimport uint32_t, uint64_t, int8_t, int16_t, int64_t

cdef extern from "pdc_public.h":
    ctypedef int                perr_t
    ctypedef uint64_t           pdcid_t
    ctypedef unsigned long long psize_t
    ctypedef bint               pbool_t

    ctypedef int PDC_int_t

    ctypedef enum pdc_lifetime_t:
        PDC_PERSIST
        PDC_TRANSIENT
    ctypedef enum:
        SUCCEED = 0
        FAIL = -1
    ctypedef enum pdc_var_type_t:
        PDC_UNKNOWN  = -1
        PDC_INT      = 0
        PDC_FLOAT    = 1
        PDC_DOUBLE   = 2
        PDC_CHAR     = 3
        PDC_COMPOUND = 4
        PDC_ENUM     = 5
        PDC_ARRAY    = 6
        PDC_UINT     = 7
        PDC_INT64    = 8
        PDC_UINT64   = 9
        PDC_INT16    = 10
        PDC_INT8     = 11
        NCLASSES     = 12
    
    ctypedef struct pdc_histogram_t:
        pdc_var_type_t dtype
        int            nbin
        double         incr
        double *       range
        uint64_t *     bin

cdef extern from "pdc.h":
    pdcid_t PDCinit(const char *pdc_name)
    perr_t PDCclose(pdcid_t pdcid)

cdef extern from "pdc_id_pkg.h":
    ctypedef struct _pdc_id_info:
        pdcid_t           id
        void *            obj_ptr

cdef extern from "pdc_cont.h":
    ctypedef _pdc_id_info cont_handle
    struct pdc_cont_info:
        char *   name
        pdcid_t  local_id
        uint64_t meta_id
    
    pdcid_t PDCcont_create(const char *cont_name, pdcid_t cont_create_prop)
    #pdcid_t PDCcont_create_col(const char *cont_name, pdcid_t cont_prop_id)
    pdcid_t PDCcont_open(const char *cont_name, pdcid_t pdc_id)
    #pdcid_t PDCcont_open_col(const char *cont_name, pdcid_t pdc_id)
    perr_t PDCcont_close(pdcid_t cont_id)
    perr_t PDCcont_persist(pdcid_t cont_id)
    perr_t PDCprop_set_cont_lifetime(pdcid_t cont_create_prop, pdc_lifetime_t cont_lifetime)
    pdcid_t PDCcont_get_id(const char *cont_name, pdcid_t pdc_id)

    #low priority, but straightforward to implement
    cont_handle *PDCcont_iter_start()
    cont_handle *PDCcont_iter_next(cont_handle *chandle)
    pbool_t PDCcont_iter_null(cont_handle *chandle)
    pdc_cont_info *PDCcont_iter_get_info(cont_handle *chandle)
    
    perr_t PDCcont_del(pdcid_t cont_id)
    perr_t PDCcont_put_objids(pdcid_t cont_id, int nobj, pdcid_t *obj_ids)
    perr_t PDCcont_del_objids(pdcid_t cont_id, int nobj, pdcid_t *obj_ids)
    perr_t PDCcont_put_tag(pdcid_t cont_id, char *tag_name, void *tag_value, psize_t value_size)
    perr_t PDCcont_get_tag(pdcid_t cont_id, char *tag_name, void **tag_value, psize_t *value_size)
    perr_t PDCcont_del_tag(pdcid_t cont_id, char *tag_name)

cdef extern from "pdc_cont_pkg.h":
    struct _pdc_cont_info:
        pdc_cont_info * cont_info_pub
        _pdc_cont_prop *cont_pt
    
    _pdc_cont_info *PDC_cont_get_info(pdcid_t cont_id)

cdef extern from "pdc_obj.h":
    ctypedef _pdc_id_info obj_handle
    struct pdc_obj_info:
        char *       name
        pdcid_t      meta_id
        pdcid_t      local_id
        int          server_id
        pdc_obj_prop *obj_pt
    ctypedef enum pdc_access_t:
        PDC_NA = 0
        PDC_READ = 1
        PDC_WRITE = 2

    pdcid_t PDCobj_create(pdcid_t cont_id, const char *obj_name, pdcid_t obj_create_prop)
    pdcid_t PDCobj_open(const char *obj_name, pdcid_t pdc_id)
    perr_t PDCobj_del(pdcid_t obj_id)
    #pdcid_t PDCobj_open_col(const char *obj_name, pdcid_t pdc_id)
    perr_t PDCobj_close(pdcid_t obj_id)
    pdc_obj_info *PDCobj_get_info(pdcid_t obj)
    perr_t PDCprop_set_obj_user_id(pdcid_t obj_prop, uint32_t user_id)
    perr_t PDCprop_set_obj_app_name(pdcid_t obj_prop, char *app_name)
    perr_t PDCprop_set_obj_time_step(pdcid_t obj_prop, uint32_t time_step)    
    perr_t PDCprop_set_obj_dims(pdcid_t obj_prop, PDC_int_t ndim, uint64_t *dims)
    perr_t PDCprop_set_obj_type(pdcid_t obj_prop, pdc_var_type_t type)
    _pdc_obj_info *PDC_obj_get_info(pdcid_t obj_id)

    #low priority, but straightforward to implement:
    obj_handle *PDCobj_iter_start(pdcid_t cont_id)
    pbool_t PDCobj_iter_null(obj_handle *ohandle)
    obj_handle *PDCobj_iter_next(obj_handle *ohandle, pdcid_t cont_id)
    pdc_obj_info *PDCobj_iter_get_info(obj_handle *ohandle)
    pdcid_t PDCobj_put_data(const char *obj_name, void *data, uint64_t size, pdcid_t cont_id)
    perr_t PDCobj_get_data(pdcid_t obj_id, void *data, uint64_t size)
    perr_t PDCobj_del_data(pdcid_t obj_id)
    perr_t PDCobj_put_tag(pdcid_t obj_id, char *tag_name, void *tag_value, psize_t value_size)
    perr_t PDCobj_get_tag(pdcid_t obj_id, char *tag_name, void **tag_value, psize_t *value_size)
    perr_t PDCobj_del_tag(pdcid_t obj_id, char *tag_name)

cdef extern from "pdc_obj_pkg.h":
    cdef struct _pdc_obj_info:
        _pdc_obj_prop *      obj_pt

#low priority:

#cdef extern from "pdc_analysis.h":
#    pdcid_t PDCobj_data_iter_create(pdcid_t obj_id, pdcid_t reg_id)
#    pdcid_t PDCobj_data_block_iterator_create(pdcid_t obj_id, pdcid_t reg_id, int contig_blocks)
#    size_t PDCobj_data_getSliceCount(pdcid_t iter)
#    size_t PDCobj_data_getNextBlock(pdcid_t iter, void **nextBlock, size_t *dims)
#    perr_t PDCobj_analysis_register(char *func, pdcid_t iterIn, pdcid_t iterOut)
#    int PDCiter_get_nextId()

#nothing from "pdc_dt_conv.h", "pdc_hist_pkg.h" included because it is never mentioned in the examples or tests

cdef extern from "pdc_prop.h":
    struct pdc_obj_prop:
        #not used:
        #pdcid_t        obj_prop_id
        size_t         ndim
        uint64_t *     dims
        pdc_var_type_t type
    
    ctypedef enum pdc_prop_type_t:
        PDC_CONT_CREATE = 0
        PDC_OBJ_CREATE
    
    pdcid_t PDCprop_create(pdc_prop_type_t type, pdcid_t pdc_id)
    perr_t PDCprop_close(pdcid_t id)
    #does not copy most properties.  not that useful:
    #pdcid_t PDCprop_obj_dup(pdcid_t prop_id)

cdef extern from "pdc_prop_pkg.h":
    struct _pdc_obj_prop:
        pdc_obj_prop *obj_prop_pub
        uint32_t             user_id
        char *               app_name
        uint32_t             time_step
    
    struct _pdc_cont_prop:
        pdc_lifetime_t     cont_life
        _pdc_class *pdc

    _pdc_obj_prop *PDC_obj_prop_get_info(pdcid_t obj_prop)


cdef extern from "pdc_region.h":
    struct pdc_region_info:
        pdcid_t               local_id
        size_t                ndim
        uint64_t *            offset
        uint64_t *            size
        bint                  mapping
        int                   registered_op
        void *                buf
        size_t                unit
    
    ctypedef enum pdc_transfer_status_t:
        PDC_TRANSFER_STATUS_COMPLETE  = 0
        PDC_TRANSFER_STATUS_PENDING   = 1
        PDC_TRANSFER_STATUS_NOT_FOUND = 2
    
    pdcid_t PDCregion_create(psize_t ndims, uint64_t *offset, uint64_t *size)
    perr_t PDCregion_close(pdcid_t region_id)
    pdcid_t PDCregion_transfer_create(void *buf, pdc_access_t access_type, pdcid_t obj_id, pdcid_t local_reg, pdcid_t remote_reg)
    perr_t PDCregion_transfer_start(pdcid_t transfer_request_id)
    #perr_t PDCregion_transfer_start_all(pdcid_t *transfer_request_id, size_t size)
    perr_t PDCregion_transfer_status(pdcid_t transfer_request_id, pdc_transfer_status_t *completed)
    perr_t PDCregion_transfer_wait(pdcid_t transfer_request_id)
    #perr_t PDCregion_transfer_wait_all(pdcid_t *transfer_request_id, size_t size)
    perr_t PDCregion_transfer_close(pdcid_t transfer_request_id)

cdef extern from "pdc_query.h":
    #cdef enum pdc_prop_name_t:
    #    PDC_OBJ_NAME
    #    PDC_CONT_NAME
    #    PDC_APP_NAME
    #    PDC_USER_ID

    ctypedef enum pdc_query_op_t:
        PDC_OP_NONE = 0
        PDC_GT = 1
        PDC_LT = 2
        PDC_GTE = 3
        PDC_LTE = 4
        PDC_EQ = 5

    ctypedef enum pdc_query_combine_op_t:
        PDC_QUERY_NONE = 0
        PDC_QUERY_AND = 1
        PDC_QUERY_OR = 2
    
    ctypedef struct pdc_selection_t:
        pdcid_t   query_id
        size_t    ndim
        uint64_t  nhits
        uint64_t *coords
        uint64_t  coords_alloc

    ctypedef struct pdc_query_constraint_t:
        pdcid_t          obj_id
        pdc_query_op_t   op
        pdc_var_type_t   type
        double           value
        pdc_histogram_t *hist

        int            is_range
        pdc_query_op_t op2
        double         value2

        void *  storage_region_list_head
        pdcid_t origin_server
        int     n_sent
        int     n_recv

    ctypedef struct pdc_query_t:
        pdc_query_constraint_t *constraint
        pdc_query_t *    left
        pdc_query_t *    right
        pdc_query_combine_op_t  combine_op
        pdc_region_info *region
        void *                  region_constraint
        pdc_selection_t *       sel

    pdc_query_t *PDCquery_create(pdcid_t obj_id, pdc_query_op_t op, pdc_var_type_t type, void *value)
    pdc_query_t *PDCquery_and(pdc_query_t *query1, pdc_query_t *query2)
    pdc_query_t *PDCquery_or(pdc_query_t *query1, pdc_query_t *query2)
    #perr_t PDCobj_prop_query(pdcid_t cont_id, pdc_prop_name_t prop_name, void *prop_value, pdcid_t **out_ids, size_t *n_out)
    perr_t PDCquery_sel_region(pdc_query_t *query, pdc_region_info *obj_region)
    perr_t PDCquery_get_selection(pdc_query_t *query, pdc_selection_t *sel)
    perr_t PDCquery_get_nhits(pdc_query_t *query, uint64_t *n)
    perr_t PDCquery_get_data(pdcid_t obj_id, pdc_selection_t *sel, void *obj_data)

    perr_t PDCquery_get_sel_data(pdc_query_t *query, pdc_selection_t *sel, void *data)
    void PDCselection_free(pdc_selection_t *sel)
    void PDCquery_free(pdc_query_t *query)
    void PDCquery_free_all(pdc_query_t *query) #?
    void PDCquery_print(pdc_query_t *query)

cdef extern from "pdc_prop_pkg.h":
    ctypedef struct pdc_kvtag_t:
        char *   name
        uint32_t size
        void *   value

cdef extern from "pdc_malloc.h":
    void *PDC_free(void *mem)

cdef extern from "pdc_private.h":
    cdef struct _pdc_class:
        char *  name
        pdcid_t local_id


#cdef extern from "pdc_client_connect.h":
#    perr_t PDC_Client_query_kvtag(pdc_kvtag_t *kvtag, int *n_res, uint64_t **pdc_ids)

#low priority:
#cdef extern from "pdc_transform.h":
#    ctypedef enum pdc_obj_transform_t:
#        PDC_TESTING       = 0
#        PDC_FILE_IO       = 1
#        PDC_DATA_MAP      = 2
#        PDC_PRE_ANALYSIS  = 4
#        PDC_POST_ANALYSIS = 8
#    
#    ctypedef enum pdc_data_movement_t:
#        DATA_IN = 1
#        DATA_OUT = 2
#        DATA_RELOCATION = 4
#    
#    #These functions will have to be changed significantly to be able to accept python functions as arguments
#    #They will need to accept a function pointer directly and an arbitrary void* argument to pass to the function
#    perr_t PDCobj_transform_register(char *func, pdcid_t obj_id, int current_state, int next_state, pdc_obj_transform_t op_type, pdc_data_movement_t when) #?
#    perr_t PDCbuf_map_transform_register(char *func, void *buf, pdcid_t src_region_id, pdcid_t dest_object_id, pdcid_t dest_region_id, int current_state, int next_state, pdc_data_movement_t when) #?
