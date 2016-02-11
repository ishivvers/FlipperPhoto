"""Wrapper around astrometry.net, as currently installed
on heracles.

-Isaac, Feb. 5
"""
from subprocess import Popen, PIPE
import fileio
import os

def astrometry_kait( filepath, outfilepath ):
    """Attempt to find updated World Coordinate System (WCS)
    information for a KAIT image.

    TO_DO:
        Force astrometry to use sextractor result (Weikang says that should work better).
        See here: http://astrometry.net/doc/readme.html#sextractor
    """
    # properties of the KAIT camera
    pixscale=0.7965
    pixscaleL=0.79
    pixscaleH=0.80
    searchradius=0.3 #in degree
    width=500  #image width in pixel
    height=500 #image height in pixel
    conffile = "/usr/local/astrometry/etc/astrometry.cfg"
    
    # first make sure the fits header is fixed up appropriately.
    ## For now, this overwrites the original file, so DO NOT PERFORM
    ##  ON ANY ORIGINAL DATA!!!
    filepath = fileio.fix_kait_header( filepath )
    base,ext = os.path.splitext( filepath )
    solvedfile = "%s.solved.fits"%base

    # pull relevant info out of the header
    header = fileio.get_head( filepath )

    astrometry_args = " -3 %s"%header['RA'] + " -4 %s"%header["DEC"] + " -5 %f"%searchradius +\
                      " --scale-units arcsecperpix -L %f"%pixscaleL + " -H %f"%pixscaleH +\
                      " -D %s"%outfilepath + " -N %s"%solvedfile + " -b %s"%conffile +\
                      " -O -p -y -2  -t 1 --no-plots "
    cmd = "solve-field" + astrometry_args + filepath
    print cmd
    o,e = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
    print 'out:',o
    print 'err:',e
    return solvedfile


def astrometry_nickel( filepath, outfilepath ):
    """Attempt to find updated World Coordinate System (WCS)
    information for an Nickel image.

    TO_DO:
        Force astrometry to use sextractor result (Weikang says that should work better).
        See here: http://astrometry.net/doc/readme.html#sextractor
    """
    # properties of the Nickel camera
    pixscale=0.37088
    pixscaleL=0.36
    pixscaleH=0.38
    searchradius=0.3 #in degree
    width=1024 #image width in pixel
    height=1024#image height in pixel
    conffile = "/usr/local/astrometry/etc/astrometry.cfg"
    
    # pull relevant info out of the header
    header = fileio.get_head( filepath )
    base,ext = os.path.splitext( filepath )
    solvedfile = "%s.solved.fits"%base

    astrometry_args = " -3 %s"%header['RA'] + " -4 %s"%header["DEC"] + " -5 %f"%searchradius +\
                      " --scale-units arcsecperpix -L %f"%pixscaleL + " -H %f"%pixscaleH +\
                      " -D %s"%outfilepath + " -N %s"%solvedfile + " -b %s"%conffile +\
                      " -O -p -y -2  -t 1 --no-plots "
    cmd = "solve-field" + astrometry_args + filepath
    print cmd
    o,e = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
    print 'out:',o
    print 'err:',e
    return solvedfile
