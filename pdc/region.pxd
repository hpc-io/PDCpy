from pdc.cpdc cimport pdc_region_info

cdef void free_region_info(pdc_region_info *region_info)
cdef pdc_region_info *construct_region_info(region, dims)