# FlipperPhoto
The UCB Filippenko Group's Photometry Pipeline

This repository houses the code used by UC Berkeley's Filippenko Group
to autonomously produce a database of rough (not publication-quality) photometry
of all sources detected in all images we've ever obtained with the Nickel
and KAIT telescopes at Lick Observatory.

-2017, I.Shivvers & T.Tu


## Steps:

 - We start with the flat-fielded and bias-subtracted images.
   - This code was built with the Nickel and KAIT telescopes in mind, but we have endeavored
    to make it easy to update for other instruments.
 - Update WCS information using ``astrometry.net``.
 - Identify objects and perform photometry using ``source extractor``.
 - Cross-match to calibrated ``APASS`` catalog to place that photometry on an absolute scale.
 - Insert result into a MySQL database for easy querying.
   - This database has been interfaced with the Berkeley [SNDB](http://heracles.astro.berkeley.edu/sndb/) 

## Installation:

 1. Clone this repository.
 1. Verify that you have both ``sextractor`` ([Source Extractor](http://www.astromatic.net/software/sextractor)) and ``solve-field`` ([astrometry.net](http://astrometry.net/)) installed.
 1. Create a file called ``local.py`` in ``FlipperPhot/flipp/conf/``. 
   1. Within this file you should re-define anything you need to from ``global_settings.py``. (The contents of ``local.py`` over-ride those of ``global_settings.py``.)
   1. For example, you will likely want to re-define the ``DB_URL`` variable, which points to the database where you want to store the output ([see here](http://docs.sqlalchemy.org/en/latest/core/engines.html)). The database must already exist, but ``FlipperPhot`` will automatically create the tables it needs.
   1. Other likely changes:
     1. ``SEXTRACTORPATH:`` the path to the ``sextractor`` executable.
     1. ``SOLVEFIELDPATH:`` the path to the ``solve-field`` executable.
     1. ``ASTROMETRYCONF:`` the path to the ``solve-field`` configuration file, which usually contains system-specific info.
 1. Within the root folder of FlipperPhot, run ``pip install .`` to install.
   1. Now you should have the command ``flipprun`` in your path.
   1. Type ``flipprun -h`` for information on how to run it.

