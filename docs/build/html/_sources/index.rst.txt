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

.. automodule:: pdc.main
   :members:
   :undoc-members:

Containers
==========

.. automodule:: pdc.container
   :members:
   :undoc-members:

Objects
=======

.. automodule:: pdc.object
   :members:
   :undoc-members:

Regions
=======

.. automodule:: pdc.region
   :members:
   :undoc-members:

   .. property:: region
   
   	An object used to create regions.
   	See :class:`Region` for details.

Queries
=======

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
