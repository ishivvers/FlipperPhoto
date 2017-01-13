# FlipperPhoto
The UCB Filippenko Group's Photometry Pipeline

This repository houses the code used by UC Berkeley's Filippenko Group
to autonomously produce a database of rough (not publication-quality) photometry
of all sources detected in all images we've ever obtained with the Nickel
and KAIT telescopes at Lick Observatory.

-2017, I.Shivvers & T.Tu


## Our goals:

 - We start with the flat-fielded and bias-subtracted KAIT and Nickel images. 
 - Produce a set of codes that can be run in sequence to take
   raw images from the KAIT and Nickel telescopes and produce
   calibrated photometry fully autonomously.  I.E. a "data pipeline".
  - Design the pipeline so that it can be run on archived data and on new
    images moving forward.
 - Build a database using the results, and interface it with the
   [SNDB](http://heracles.astro.berkeley.edu/sndb/) website.
 - Update our methods of checking new images for new transients ("kait checking"),
   incorporating new techniques where necessary 
   (i.e., [this paper](http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=2016arXiv160102655Z&db_key=PRE&link_type=ABSTRACT&high=5370fb403432352))

## Installation:

 1. Clone this repository.
 1. Verify that you have both ``sextractor`` ([Source Extractor](http://www.astromatic.net/software/sextractor)) and ``solve-field`` ([astrometry.net](http://astrometry.net/)) installed.
 1. Create a file called ``local.py`` in ``FlipperPhot/flipp/conf/``. 
   1. Within this file you should re-define anything you need to from ``global_settings.py``. (The contents of ``local.py`` over-ride those of ``global_settings.py``.)
   1. For example, you will likely want to re-define the ``DB_URL`` variable, which points to the database where you want to store the output ([see here](http://docs.sqlalchemy.org/en/latest/core/engines.html)). The database must already exist, but ``FlipperPhot`` will automatically create the tables it needs.
   1. Other likely changes:
     1. ``SEXTRACTORPATH:`` the path to the ``sextractor`` executable.
     1. ``SOLVEFIELDPATH:`` the path to the ``solve-field`` executable.
     1. ``ASTROMETRYCONF:`` the path to the ``solve-field/astrometry.net`` configuration file, which usually contains system-specific info.
 1. Within the root folder of FlipperPhot, run ``pip install -e .`` to install.
   1. Now you should have the command ``flipprun`` in your path.
   1. Type ``flipprun -h`` for information on how to run it.

### To Do:

- Devise a better method for "validating" imges before we attempt to calculate the astrometry; ideally we could determine whether an image is good or not before then.
  - extreme examples of "bad" images: ``Data/kait/2013/Jun25/Jun3pind.fts.Z``, ``Data/kait/2015/Sep30/Sep5uihp.fts.Z``
  - examples of "good" images: ``Data/kait/2015/May20/May5khhh.fts.Z``, ``Data/nickel/nickel150609/data/tfn150609.d206.sn2014c.V.fit``
- Finish integrating result with the SNDB.