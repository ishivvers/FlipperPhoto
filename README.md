# FlipperPhoto
The UCB Filippenko Group's Photometry Pipeline


## Our goals:

 - Produce a set of codes that can be run in sequence to take 
   raw images from the KAIT and Nickel telescopes and produce 
   calibrated photometry fully autonomously.  I.E. a "data pipeline".
  - Design the pipeline so that it can be run on archived data and on new
    images moving forward.
 - Interface the output of this pipeline with the [SNDB](http://heracles.astro.berkeley.edu/sndb/) website, probably through a database of all photometry.
 - Update our methods of checking new images for new transients ("kait checking"),
   incorporating new techniques where necessary (i.e. [this paper](http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=2016arXiv160102655Z&db_key=PRE&link_type=ABSTRACT&high=5370fb403432352))


## Our starting point:

We will start from the flat-fielded and bias-subtracted KAIT and Nickel images. (At some point, the code used to do these steps may require re-writing, but for now we will punt that task.)


### KAIT:

The KAIT images are stored here: ``/media/raid0/Data/kait/YYYY/MonDD/*.fts.Z``
They are either raw fits images or zipped fits images, and they can be opened directly with DS9 or in python as shown in ``examples.py``.  (Some fits warnings will pop up for KAIT images; you can safely ignore those.)

The filenames within the folder are named with unintelligble strings; don't worry about them (that was an early system of encoding filenames as a sort of hash, to prevent any duplicate filenames).  In the same folders there is a file called ``insgen.log`` (sometimes with a ``.Z`` suffix) that is a robotically-generated log of every action the telescope took that night.  If it successfully observed something, it records that in this log.  In the ``examples.py`` file I include a quick way to parse that verbose logfile to look to see what object each file observed (but note that info is in the fits file header under ``object`` as well).

All fits files in those folders have been flatfiled-corrected and bias corrected and are ready to go into the next step (see below).


### Nickel:

The Nickel images are stored here: ``/media/raid0/Data/nickel/nickelYYMMDD/data/tfn*.fit``
The filenames here start with tfn (Trimmed, Flatfielded, Nickel images), then include the date as YYMMDD, then the original filename of the raw image, then the object name (from the fits header), and finally the passband through which it was observed.

These files have been flatfield-corrected, bias-corrected, and trimmed, but the other files in the same folder (i.e., n*.fit) are the un-corrected versions.  We will use the tfn*.fit files.


## Current status and to-do:

 - Produce flat-fielded and bias-subtracted images from raw data for each telescope in a consistent manner
  - DONE
 - Determine which of those images are "good" and worth working with, and which are "crap" (maybe bad weather, instrument problems, or KAIT going out of focus, etc.)
  - Ready to begin
 - For every good image, calculate the WCS using (astrometry.net)[http://astrometry.net/use.html] code
  - there is an installation of this code at ``/home/kait/software_instealled/astrometry/bin``, I will install it system-wide soon
  - Ready to begin
 - After the WCS information is added to the image header, move the file to ``/media/raid0/Data/reduced_images/TELESCOPE/YYYYMMDD/*``, and rename the file to the following convention:
   - targetName_YYYYMMDD.dd_k/n_filter_c.fit
    - use k or n to demarcate KAIT or Nickel
    - filter should be one of B,V,R,I, or clear
    - targetName from the file header
    - YYYYMMDD.dd is observation date with decimal days
  - Ready to begin
 - to be continued...

