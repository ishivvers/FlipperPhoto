# -*- coding : utf-8 -*-

import os

from astropy.io import fits
import numpy as np

from conf import FIXTURE_DIR

GKAIT = os.path.join(FIXTURE_DIR, 'kait', 'goodkait.fits')

def image_factory(length):
    """Creates a fake image with a single source object in the center."""
    data = np.zeros((length,)*2) # Create a L x L blank image
    mean = [length//2.]*2 # Roughly center the image
    cov = [(np.sqrt(length)//2.,0), (0, np.sqrt(length)//2.)] # I think this is something
    x, y = np.random.multivariate_normal(mean, cov, int(1E5)).T
    coords = zip(x.astype(int), y.astype(int))
    for c in coords:
        data[c] += 1.
    hdu = fits.hdu.image.PrimaryHDU(data = data)
    return fits.hdu.hdulist.HDUList(hdus=hdu)