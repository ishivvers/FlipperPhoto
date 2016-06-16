import numpy as np

from flipp.libs.coord import ang_sep, indmatch
from flipp.libs.apass import Client as APASS

def gri2R( g,r,i ):
    """Use the transformations listed at http://classic.sdss.org/dr7/algorithms/sdssUBVRITransform.html
    to transform gri passbands into an estimate of R.

    Returns array of R and float estimate of systematic RMS error of transformation.
    """
    V = g - 0.58*(g-r) - 0.01
    R = V - (0.38*(r-i) + 0.27)
    return R, (0.02**2 + 0.02**2)**0.5

def Zeropoint_apass( sources, passband='clear' ):
    """Given a source extractor catalog calculated from a single image,
    calculate the zero point (in magnitudes) of that image and return
    a catalog of sources with magnitudes and errors.

    Uses the APASS catalog to calculate the zero point.

    Example
    -------

    .. code-block::

        from flipp.libs.zeropoint import Zeropoint
        from flipp.libs.sextractor import Sextractor
        from flipp.libs.astrometry import Astrometry
        
        gkait = "flipp/fixtures/kait/goodkait.fits"
        x = Astrometry(gkait, 'kait')
        s = Sextractor()
        e = x.solve(N = 'TEST.fits')
        sources = s.extract(e)
        
        sources = zeropoint(sources)
    """

    # find the middle of the field found in the image
    ra_c = np.mean( sources['ALPHA_J2000'] )
    dec_c = np.mean( sources['DELTA_J2000'] )
    # find the radius needed to capture the whole field, taking spherical 
    #  geometry into account
    radius = np.max( ang_sep(sources['ALPHA_J2000'],sources['DELTA_J2000'], ra_c,dec_c) )
    radius += 0.05 # add some slack, just to be safe
    apass_sources = APASS.query(ra_c, dec_c, radius)
    
    # cross match the two catalogs
    image_matches, catalog_matches = indmatch( sources['ALPHA_J2000'],sources['DELTA_J2000'],
                                    apass_sources['radeg'],apass_sources['decdeg'], 1.0) # using a tolerance of 1.0" for now

    image_cat = sources[ image_matches ]
    apass_cat = apass_sources[ catalog_matches ]
    if passband == 'clear':
        # transform the catalog values to R passband, which is roughly right
        apass_cat[passband],err = gri2R( np.array(apass_cat['Sloan_g']),
                                  np.array(apass_cat['Sloan_r']),
                                  np.array(apass_cat['Sloan_i']) )
    else:
        raise Exception('Passband not yet implemented.')

    # take the median as the zeropoint
    zp = np.median(apass_cat[passband] - image_cat['MAG_AUTO'])

    # apply that zeropoint to all sources and return the fixed up catalog
    sources['MAG_AUTO_ZP'] = sources['MAG_AUTO']+zp
    return sources
