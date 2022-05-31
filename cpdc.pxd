from libc.stdint cimport (uint8_t, uint16_t, uint32_t, uint64_t)

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

cdef extern from "pdc_prop.h":
    ctypedef struct pdc_obj_prop:
        pdcid_t        obj_prop_id
        size_t         ndim
        uint64_t *     dims
        pdc_var_type_t type


cdef extern from "pdc.h":
    pdcid_t PDCinit(const char *pdc_name)
    perr_t PDCclose(pdcid_t pdcid)

cdef extern from "pdc_id_pkg.h":
    ctypedef struct _pdc_id_info:
        pdcid_t           id
        void *            obj_ptr
        #next and prev pointers ommitted, as well as count variable

cdef extern from "pdc_cont.h":
    ctypedef _pdc_id_info cont_handle
    ctypedef struct pdc_cont_info:
        char *   name
        pdcid_t  local_id
        uint64_t meta_id
    pdcid_t PDCcont_create(const char *cont_name, pdcid_t cont_create_prop)
    pdcid_t PDCcont_create_col(const char *cont_name, pdcid_t cont_prop_id) #?
    pdcid_t PDCcont_open(const char *cont_name, pdcid_t pdc_id)
    pdcid_t PDCcont_open_col(const char *cont_name, pdcid_t pdc_id) #?
    perr_t PDCcont_close(pdcid_t cont_id)
    pdc_cont_info *PDCcont_get_info(const char *cont_name)
    perr_t PDCcont_persist(pdcid_t cont_id)
    perr_t PDCprop_set_cont_lifetime(pdcid_t cont_create_prop, pdc_lifetime_t cont_lifetime)
    pdcid_t PDCcont_get_id(const char *cont_name, pdcid_t pdc_id)
    cont_handle *PDCcont_iter_start()
    pbool_t PDCcont_iter_null(cont_handle *chandle)
    pdc_cont_info *PDCcont_iter_get_info(cont_handle *chandle)
    perr_t PDCcont_del(pdcid_t cont_id)
    perr_t PDCcont_put_objids(pdcid_t cont_id, int nobj, pdcid_t *obj_ids) #does this change the container an object is in?
    perr_t PDCcont_del_objids(pdcid_t cont_id, int nobj, pdcid_t *obj_ids)
    perr_t PDCcont_put_tag(pdcid_t cont_id, char *tag_name, void *tag_value, psize_t value_size)
    perr_t PDCcont_get_tag(pdcid_t cont_id, char *tag_name, void **tag_value, psize_t *value_size)
    perr_t PDCcont_del_tag(pdcid_t cont_id, char *tag_name)

    #not implemented:
    #perr_t PDCcont_get_objids(pdcid_t cont_id, int *nobj, pdcid_t **obj_ids)

cdef extern from "pdc_obj.h":
    ctypedef _pdc_id_info obj_handle
    ctypedef struct pdc_obj_info:
        char *       name
        pdcid_t      meta_id
        pdcid_t      local_id
        int          server_id
        pdc_obj_prop *obj_pt

    pdcid_t PDCobj_create(pdcid_t cont_id, const char *obj_name, pdcid_t obj_create_prop)
    pdcid_t PDCobj_open(const char *obj_name, pdcid_t pdc_id)
    pdcid_t PDCobj_open_col(const char *obj_name, pdcid_t pdc_id)
    perr_t PDCobj_close(pdcid_t obj_id)
    pdc_obj_info *PDCobj_get_info(pdcid_t obj)
    #not implemented:
    #perr_t PDCobj_get_id(const char *tag_name, void *tag_value, int value_size, int *n_res, uint64_t **pdc_ids);
    #perr_t PDCobj_get_name(const char *tag_name, void *tag_value, int value_size, int *n_res, char **obj_names);
    perr_t PDCprop_set_obj_user_id(pdcid_t obj_prop, uint32_t user_id)
    perr_t PDCprop_set_obj_data_loc(pdcid_t obj_prop, char *app_name) #?
    perr_t PDCprop_set_obj_app_name(pdcid_t obj_prop, char *app_name)
    perr_t PDCprop_set_obj_time_step(pdcid_t obj_prop, uint32_t time_step)
    perr_t PDCprop_set_obj_tags(pdcid_t obj_prop, char *tags)
    perr_t PDCprop_set_obj_dims(pdcid_t obj_prop, PDC_int_t ndim, uint64_t *dims)
    perr_t PDCprop_set_obj_type(pdcid_t obj_prop, pdc_var_type_t type)
    perr_t PDCprop_set_obj_buf(pdcid_t obj_prop, void *buf) #?
    void **PDCobj_buf_retrieve(pdcid_t obj_id) #?
    obj_handle *PDCobj_iter_start(pdcid_t cont_id)
    pbool_t PDCobj_iter_null(obj_handle *ohandle)
    obj_handle *PDCobj_iter_next(obj_handle *ohandle, pdcid_t cont_id)
    pdc_obj_info *PDCobj_iter_get_info(obj_handle *ohandle)
    obj_handle *PDCview_iter_start(pdcid_t view_id) #Aren't queries over the contents of objects?

    pdcid_t PDCobj_put_data(const char *obj_name, void *data, uint64_t size, pdcid_t cont_id)
    perr_t PDCobj_get_data(pdcid_t obj_id, void *data, uint64_t size)
    perr_t PDCobj_del_data(pdcid_t obj_id)
    perr_t PDCobj_put_tag(pdcid_t obj_id, char *tag_name, void *tag_value, psize_t value_size)
    perr_t PDCobj_get_tag(pdcid_t obj_id, char *tag_name, void **tag_value, psize_t *value_size)
    perr_t PDCobj_del_tag(pdcid_t obj_id, char *tag_name)
