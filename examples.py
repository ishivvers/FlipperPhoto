"""
A set of examples to get everyone on the same page
and started off.

-Isaac, Jan. 15
"""
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.colors import LogNorm
import numpy as np
from astropy.io import fits as pf
from subprocess import Popen, PIPE
from cStringIO import StringIO
import re


def get_zipped_fitsfile( pathname ):
    """
    Open a zipped fits file.
     Returns: astropy.io.fits / pyfits object
    """
    p = Popen(["zcat", pathname], stdout=PIPE)
    hdu = pf.open( StringIO(p.communicate()[0]) )
    # avoid some dumb bugs, not important
    hdu.verify('fix')
    return hdu

def plot_one_image( pathname='/media/raid0/Data/nickel/nickel150609/data/tfn150609.d206.sn2014c.V.fit' ):
    """
    Plot a KAIT or Nickel image using matplotlib, using scaling parameters
     that generally work well.
    """
    try:
        hdu = pf.open( pathname )
    except IOError:
        # probably a zcatted image
        hdu = get_zipped_fitsfile( pathname )

    # the header is accessible like a dictionary:
    header = hdu[0].header
    # the data is accessible as a numpy array:
    data = hdu[0].data

    # the super simple way to inspect the file within Python is via imshow, but
    #  fancier alternatives exist too.
    plt.imshow( data, cmap=cm.gray, norm=LogNorm(np.percentile(data,50), np.percentile(data,99.9)) )
    plt.show()

def parse_insgenlog( pathname ):
    """
    Parse a KAIT-produced insgen.log file (or zipped version, insgen.log.Z).
     Returns: a dictionary of file name and observed object.
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