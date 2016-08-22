"""Library for file I/O and related tasks.

-Isaac, Feb. 5
"""

import os
import re
import numpy as np
import matplotlib.pyplot as plt

import astropy
from astropy.io import fits as pf
from cStringIO import StringIO
from matplotlib import cm
from matplotlib.colors import LogNorm 
from subprocess import Popen, PIPE

from conf import FIXTURE_DIR 


def get_zipped_fitsfile(pathname):
    """Open a zipped fits file.

    Parameters
    ----------
    pathname : str
        filepath to zipped fits file

    Returns
    -------
    hdu : astropy.io.fits.hdu.image.PrimaryHDU
        pyFits object
    """
    p = Popen(["zcat", pathname], stdout=PIPE)
    hdu = pf.open( StringIO(p.communicate()[0]) )
    # avoid some dumb bugs, not important
    hdu.verify('fix')
    return hdu

def get_head(pathname):
    """Pull the header out of a fitsfile.

    Parameters
    ----------
    pathname : str
        filepath to fitsfile

    Returns
    -------
    hdu : astropy.io.fits.hdu.image.PrimaryHDU
        pyFits object
    """
    try:
        hdu = pf.open(pathname)
    except IOError:
        # probably a zcatted image
        hdu = get_zipped_fitsfile(pathname)
    return hdu[0].header

exampleIm = os.path.join(FIXTURE_DIR, 'nickel', 'tfn150609.d206.sn2014c.V.fit')
def plot_one_image(image=exampleIm):
    """Plot first image of single fits file.
    
    Parameters
    ----------
    image : str or astropy.io.fits.hdu.hdulist.HDUList, optional
        Defaults to the fixture "tfn150609.d206.sn2014c.V.fit"

    Note
    ----
    Uses matplotlib.colors.LogNorm to scale data using 50th and 99.9th 
    percentile as ``vmin``, ``vmax`` respectively
    """
    if type(image) == astropy.io.fits.hdu.hdulist.HDUList:
        hdu = image
    else:
        try:
            hdu = pf.open(image)
        except IOError:
            # probably a zcatted image
            hdu = get_zipped_fitsfile(image)

    # the header is accessible like a dictionary:
    header = hdu[0].header
    # the data is accessible as a numpy array:
    data = hdu[0].data

    # the super simple way to inspect the file within Python is via imshow, but
    #  fancier alternatives exist too.
    vmin = np.percentile(data, 50)
    vmax = np.percentile(data, 99.9)
    plt.imshow(data, cmap=cm.gray, norm=LogNorm(vmin, vmax))
    plt.show()

 
def parse_insgenlog(pathname):
    """Parse a KAIT-produced insgen.log file.
    
    Parameters
    ----------
    pathname : str
        filepath to log file, accepts *.log and *.log.Z (zipped) files.
    
    Returns
    -------
    outd : dict
        Dictionary of the form {[filename (STR)] : [observed object (STR)]}
    """
    outd = {}
    if '.Z' in pathname:
        p = Popen(["zcat", pathname], stdout=PIPE)
        s = p.communicate()[0]
    else:
        s = open(pathname,'r').read()
    for line in s.split('\n'):
        if 'telco observes' in line:
            fname, obj = line.split()[-2:]
            outd[fname] = obj
    return outd


def fix_kait_header(pathname,outpathname=None):
    """Fix the headers in a KAIT image to be FITS-compliant,
    so that other Python codes play with them nicely.  Required before
    running astrometry solver.
    
    Parameters
    ----------
    pathname : str
        filepath to KAIT fits image to correct, accepts *.fit (or similar), or *.fit.Z (or similar).
    
    Returns
    -------
    newpathname : str
        filepath to fixed image.
    """
    try:
        hdu = pf.open(pathname)
    except IOError:
        # probably a zcatted image
        hdu = get_zipped_fitsfile(pathname)
    base,ext = os.path.splitext( pathname.strip('.Z') )
    if outpathname == None:
        outpathname = base + '.fixed' + ext
    hdu.writeto( outpathname, clobber=True, output_verify='fix' )
    return outpathname


