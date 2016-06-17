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

Let's all use [anaconda](https://www.continuum.io/downloads) python for this project (it is a big installation, but includes most of the packages we'll need).  A group version is already installed at ``/home/anaconda``.  To use it, put the following in your ``.bashrc`` file or run it by hand:

    export PATH="/home/anaconda/bin:$PATH"



## Our starting point:

We will start from the flat-fielded and bias-subtracted KAIT and Nickel images. (At some point, the code used to do these steps may require re-writing, but for now we will punt that task.)


### KAIT:

The KAIT images are stored here: ``/media/raid0/Data/kait/YYYY/MonDD/*.fts.Z``
They are either raw fits images or zipped fits images, and they can be opened directly with DS9 or in python as shown in ``examples.py``.  (Some fits warnings will pop up for KAIT images; you can safely ignore those.)

The filenames within the folder are named oddly; don't worry about those names (that was an early system of encoding filenames as a sort of hash, to prevent any duplicate filenames).  In the same folders there is a file called ``insgen.log`` (sometimes with a ``.Z`` suffix) that is a robotically-generated log of every action the telescope took that night.  If it successfully observed something, it records that in this log.  In the ``examples.py`` file I include a quick way to parse that verbose logfile to look to see what object each file observed (but note that info is in the fits file header under ``object`` as well).

All fits files in those folders have been flatfield-corrected and bias corrected and are ready to go into the next step (see below), but note that some of the files are bias frames and flat frames, and should be ignored (see insgen.log).


### Nickel:

The Nickel images are stored here: ``/media/raid0/Data/nickel/nickelYYMMDD/data/tfn*.fit``
The filenames here start with tfn (Trimmed, Flatfielded, Nickel images), then include the date as YYMMDD, then the original filename of the raw image, then the object name (from the fits header), and finally the passband through which it was observed.

These files have been flatfield-corrected, bias-corrected, and trimmed, but the other files in the same folder (i.e., ``n*.fit``) are the un-corrected versions.  We will use the ``tfn*.fit`` files.


## Current status and to-do:

 - Code currently has working astrometry and sextractor wrappers.
 - Code currently has a roughup of the pipeline structure (in 'pipeline' branch)

##### to do #####

- come up with a way to determine whether an image is "good" or "bad" before we feed it to astrometry
  - for "good" images that fail on astrometry, save them to a different location
  - weikang has code that can interactively calculate the WCS
  - we can make it easy for weikang to go through and calculate the WCS, then have him somehow mark the 
    updated files as ready to run through the rest of the pipeline
  - extreme examples of "bad" images:
   - ``/media/raid0/Data/kait/2013/Jun25/Jun3pind.fts.Z``
   - ``/media/raid0/Data/kait/2015/Sep30/Sep5uihp.fts.Z``
  - examples of "good" images:
   - ``/media/raid0/Data/kait/2015/May20/May5khhh.fts.Z``
   - ``/media/raid0/Data/nickel/nickel150609/data/tfn150609.d206.sn2014c.V.fit``
- source extractor
  - write a method to examine an image and all of the check images in a nice graphic, to see whether sextractor is 
    working as expected
  - once we have that, decide on final version for all of the sextractor parameters.  Good guide [here](http://astroa.physics.metu.edu.tr/MANUALS/sextractor/Guide2source_extractor.pdf)
- zeropoint
  - create an interface to the SDSS data
   - can do url tool like APASS, but is a bit complicated.
   - see [here](http://skyserver.sdss.org/dr12/en/tools/search/form/searchform.aspx)
  - future zeropoint cleanup:
   - use [astroquery](http://www.astropy.org/astroquery/) to access APASS data
   - plan to later have local storage of APASS data, to make this step faster
   - use [astropy coordinates](http://astropy.readthedocs.io/en/latest/coordinates/) to cross-match the APASS catalog to our source extractor catalog
- Populate a database of those results
  - in progress
