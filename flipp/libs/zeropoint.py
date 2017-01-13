import numpy as np

from flipp.libs.coord import ang_sep, indmatch
from flipp.libs.apass import Client as APASS

def gr2R( g,r ):
    """Use the Lupton 2005 transformations listed at
    http://classic.sdss.org/dr7/algorithms/sdssUBVRITransform.html
    to transform g,r passbands into R.

    Returns array of R and float estimate of systematic RMS error of transformation.
    """
    R = r - 0.1837*(g - r) - 0.0971
    sigma = 0.0106
    return R, sigma

def ri2I( r,i ):
    """Use the Lupton 2005 transformations listed at
    http://classic.sdss.org/dr7/algorithms/sdssUBVRITransform.html
    to transform r,i passbands into I.

    Returns array of I and float estimate of systematic RMS error of transformation.
    """
    I = r - 1.2444*(r - i) - 0.3820
    sigma = 0.0078
    return R, sigma

def Zeropoint_apass( sources, passband='clear' ):
    """Given a source extractor catalog calculated from a single image,
    calculate the zero point (in magnitudes) of that image and return
    a catalog of sources with magnitudes and errors.

    Uses the APASS catalog to calculate the zero point.

    Example
    -------

    .. code-block::

        from flipp.libs.zeropoint import Zeropoint_apass
        from flipp.libs.sextractor import Sextractor
        from flipp.libs.astrometry import Astrometry

        gkait = "flipp/fixtures/kait/goodkait.fits"
        x = Astrometry(gkait, 'kait')
        s = Sextractor()
        e = x.solve(N = 'TEST.fits')
        sources = s.extract(e)
        sources,zp,N = Zeropoint_apass(sources)
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
        # transform the catalog values to R passband, and assume clear ~ R.
        #  this is pretty close, but not at all exact - see discussion in Li+2003 (2003PASP..115..844L),
        #  and also note that the camera has been changed since then.
        apass_cat_passband,transf_err = gr2R( np.array(apass_cat['Sloan_g']),
                                              np.array(apass_cat['Sloan_r']) )
    elif passband == 'B':
        apass_cat_passband = apass_cat['Johnson_B']
        transf_err = 0.0
    elif passband == 'V':
        apass_cat_passband = apass_cat['Johnson_V']
        transf_err = 0.0
    elif passband == 'R':
        apass_cat_passband,transf_err = gr2R( np.array(apass_cat['Sloan_g']),
                                              np.array(apass_cat['Sloan_r']) )
    elif passpand == 'I':
        apass_cat_passband,transf_err = ri2I( np.array(apass_cat['Sloan_r']),
                                              np.array(apass_cat['Sloan_i']) )
    else:
        raise Exception('Passband not implemented.')

    # take the median as the zeropoint
    zp = np.median(apass_cat_passband - image_cat['MAG_AUTO'])
    N = len(image_matches)

    # apply that zeropoint to all sources and return the fixed up catalog.
    # NOTE: right now, I assume our errors dominate over any errors from the
    #  zeropoint or transforms, but this may merit improvement later.
    sources['MAG_AUTO_ZP'] = sources['MAG_AUTO']+zp
    sources['MAGERR_AUTO_ZP'] = sources['MAGERR_AUTO']
    return sources,zp,N
