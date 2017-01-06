# -*- coding:utf-8 -*-

import os

from astropy.io import fits
import numpy as np

from flipp.conf import settings

FIXTURE_DIR = settings.FIXTURE_DIR
GKAIT = os.path.join(FIXTURE_DIR, 'kait', 'goodkait.fits')

def source_factory(length, peak='center'):
    """Creates a fake image with a single source object in the center."""
    data = np.zeros((length,)*2) # Create a L x L blank image
    if peak == 'center':
        mean = [length//2.]*2 # Roughly center the image
    elif peak == 'corner':
        mean = [length]*2
    elif peak == 'side':
        mean = [length//2., length]
    else:
        raise ValueError("Peak must be one of 'center', 'corner' or 'side'")
    cov = [(np.sqrt(length)//2.,0), (0, np.sqrt(length)//2.)] # I think this is something
    x, y = np.random.multivariate_normal(mean, cov, int(1E5)).T

    coords = zip(x.astype(int)[x < length], y.astype(int)[y < length])
    for c in coords:
        data[c] += 1.
    hdu = fits.hdu.image.PrimaryHDU(data = data)
    return fits.hdu.hdulist.HDUList(hdus=hdu)
