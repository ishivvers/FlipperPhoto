"""Wrapper around astrometry.net, as currently installed
on heracles.

-Isaac, Feb. 5
"""
from subprocess import Popen, PIPE
import fileio
import os
from conf import PROJECT_DIR 
SEXCONFPATH = os.path.join( PROJECT_DIR, 'flipp', 'libs', 'sextractor_conf' )

def astrometry_kait( filepath, tmpfilepath ):
    """Attempt to find updated World Coordinate System (WCS)
    information for a KAIT image.
    """
    # properties of the KAIT camera
    pixscale=0.7965
    pixscaleL=0.79
    pixscaleH=0.80
    searchradius=0.3 #in degree
    width=500  #image width in pixel
    height=500 #image height in pixel
    conffile = "/usr/local/astrometry/etc/astrometry.cfg"
    sextractor = '/usr/bin/sextractor -FILTER_NAME /usr/share/sextractor/gauss_3.0_5x5.conv'
    
    # first make sure the fits header is fixed up appropriately.
    ## For now, this overwrites the original file, so DO NOT PERFORM
    ##  ON ANY ORIGINAL DATA!!!
    filepath = fileio.fix_kait_header( filepath )
    base,ext = os.path.splitext( filepath )
    solvedfile = "%s.solved.fits"%base

    # pull relevant info out of the header
    header = fileio.get_head( filepath )

    astrometry_args = " --ra %s"%header['RA'] + " --dec %s"%header["DEC"] + " --radius %f"%searchradius +\
                      " --scale-units arcsecperpix --scale-low %f"%pixscaleL + " --scale-high %f"%pixscaleH +\
                      " --dir %s"%tmpfilepath + " --new-fits %s"%solvedfile + " --backend-config %s"%conffile +\
                      " --overwrite --tweak-order 2 --no-plots " +\
                      " --use-sextractor --sextractor-path '%s' " %sextractor
    cmd = "solve-field" + astrometry_args + filepath
    print cmd
    o,e = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
    print 'out:',o
    print 'err:',e
    return solvedfile


def astrometry_nickel( filepath, tmpfilepath ):
    """Attempt to find updated World Coordinate System (WCS)
    information for an Nickel image.

    TO_DO:
        See if we can get Nickel images to solve better.
    """
    # properties of the Nickel camera
    pixscale=0.37088
    pixscaleL=0.36 # upper and lower bounds of arcsecperpix
    pixscaleH=0.38
    searchradius=0.3 #in degree
    width=1024 #image width in pixel
    height=1024#image height in pixel
    conffile = "/usr/local/astrometry/etc/astrometry.cfg"
    sextractor = '/usr/bin/sextractor -FILTER_NAME /usr/share/sextractor/gauss_3.0_5x5.conv'
    
    # pull relevant info out of the header
    header = fileio.get_head( filepath )
    base,ext = os.path.splitext( filepath )
    solvedfile = "%s.solved.fits"%base

    astrometry_args = " --ra %s"%header['RA'] + " --dec %s"%header["DEC"] + " --radius %f"%searchradius +\
                      " --scale-units arcsecperpix --scale-low %f"%pixscaleL + " --scale-high %f"%pixscaleH +\
                      " --dir %s"%tmpfilepath + " --new-fits %s"%solvedfile + " --backend-config %s"%conffile +\
                      " --overwrite --tweak-order 2 --no-plots " +\
                      " --use-sextractor --sextractor-path '%s' " %sextractor
    cmd = "solve-field" + astrometry_args + filepath
    print cmd
    o,e = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
    print 'out:',o
    print 'err:',e
    return solvedfile
