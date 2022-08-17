Welcome to pdc python api's documentation!
==========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

Main APIs
=========

Thoughout the documentation, you may see the following types used when an integer must be in a certain range:

===========  =================
type name    range
===========  =================
int32        -2**31 to 2**31-1
uint32       0 to 2**32-1
uint64       0 to 2**64-1
===========  =================

These bounds are checked at runtime and will result in an OverflowError if they are exceeded.

.. automodule:: pdc
   :imported-members:
   :members: KVTags, PDCError, init, ready, ServerContext
   :undoc-members:
   :exclude-members: tag_types, tag_types_union

   .. autoclass:: Type
      :members: as_numpy_type, from_numpy_type
      :show-inheritance:

      .. autoattribute:: INT32
         :annotation: 
         
         A 32-bit signed integer.

      .. autoattribute:: UINT32
         :annotation: 
         
         A 32-bit unsigned integer.
      
      .. autoattribute:: FLOAT
         :annotation: 
         
         A 32-bit floating point number.
      
      .. autoattribute:: DOUBLE
         :annotation: 
         
         A 64-bit floating point number.
            
      .. autoattribute:: INT64
         :annotation: 
         
         A 64-bit signed integer.
      
      .. autoattribute:: UINT64
         :annotation: 
         
         A 64-bit unsigned integer.
      
      .. autoattribute:: INT16
         :annotation: 
         
         A 16-bit signed integer.
      
      .. autoattribute:: INT8
         :annotation: 
         
         An 8-bit signed integer.

Containers
==========

.. automodule:: pdc
   :noindex:
   :imported-members:
   :exclude-members: containers_by_id, Container
   :members: all_local_containers

   .. autoclass:: Container
      :members:
      :exclude-members: Lifetime
      
      .. autoclass:: pdc.Container.Lifetime
         :show-inheritance:

         .. autoattribute:: pdc.Container.Lifetime.PERSISTENT
            :annotation:

            The container and all objects in it will persist across server restarts.
         
         .. autoattribute:: pdc.Container.Lifetime.TRANSIENT
            :annotation:

            The container and all objects in it will be deleted when the server restarts.

Objects
=======

.. automodule:: pdc
   :noindex:
   :imported-members:
   :members: Object

Regions
=======

.. automodule:: pdc.region
   :members:
   :undoc-members:

   .. property:: region
   
   	An object used to create regions.
   	See :class:`Region` for details.

.. _queries:

Queries
=======

Queries search for elements in an object.  They can also search for elements in multiple objects, in which case each object will be treated as a column of data, and matching rows are returned.

A query consists of one or more clauses where one object's data is compared, combined with AND (&) or OR (|)

For example, with 2 objects with these contents:

= =
a b
= =
1 2
3 3
5 8
7 0
= =

The query ``a.data > 3 | b.data > 4`` would return:

= =
a b
= =
5 8
7 0
= =

Queries can also be restricted to a specific region.

Here is a full program that performs the previous query:

.. code-block:: python
   :linenos:
   
   import pdc
   import numpy as np

   with pdc.ServerContext() as _:
      cont = pdc.Container('test')
      a = cont.object_from_array('a', [1, 3, 5, 7])
      b = cont.object_from_array('b', [2, 3, 8, 0])
      
      query = (a.data > 3) | (b.data > 4)
      result = query.get_result()
      a_data = result[a] #5 7
      b_data = result[b] #8 0

.. automodule:: pdc.query
   :members:
   :undoc-members:
   :exclude-members: Query

   .. autoclass:: pdc.Query
      :members:
      :undoc-members:
      :exclude-members: Result

      .. autoclass:: pdc.Query.Result
         :members:
         :undoc-members:

         .. property:: hits

            Number of hits in the result.
            If you *only* want the number of hits, use :func:`query.get_num_hits`
      
      
      

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
