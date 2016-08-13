# -*- coding : utf-8 -*-

from __future__ import unicode_litearls
from builtins import str

import os
import errno
import logging

from datetime import datetime
from glob import glob

from flipp.libs.sextractor import Sextractor
from flipp.libs.astrometry import Astrometry
from flipp.libs.zeropoint import Zeropoint_apass
from flipp.libs.utils import FitsIOMixin

SE = Sextractor()

import os

def mkdir(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

class ImageFailedError(Exception):
    """Simple pipeline error; raised when nothing is wrong
    but an image is bad.
    """
    pass

class ImageProcessor(FitsIOMixin, object):

    def __init__(self, filepath, telescope, output_dir):
        self.output_dir = output_dir
        self.file = filepath
        name, path, images = self._parse_input(filepath)
        self.image = images[0]
        self.header = self.image.header
        self.telescope = telescope
        self.astrometry = Astrometry(self.image, self.telescope)

    @property
    def META(self):
        if not hasattr(self, '_M'):
            t = str(self.telescope)[0].lower()
            # TEMPORARY TO WORK WITH KAIT
            HEADERMAPS = { 'FILTER' : 'filtnam', 'DATE' : 'date-obs',
                'TIME' : 'ut', 'OBJECT' : 'object'}
            H = {k : self.header[v].strip() \
                for k, v in HEADERMAPS if self.header.get(v)}
            dt = "{0} {1}".format(H['DATE'], H['TIME'].split('.')[0])
            H['DATETIME'] = datetime.strptime(dt, "%d/%m/%y %H:%M:%S")
            H['FRACTIONAL_DATE'] = '{:%Y%m%d}{}'.format(H['DATETIME'],
                '{:.4f}'.format(timedelta(
                    hours = obs_date.hour,
                    minutes = obs_date.minute,
                    seconds = obs_date.second).total_seconds()/(60.*60.*24.)).lstrip('0'))
            self._M = H
        return self._M

    def validate(self):
        """TEMPORARY!  Validate image and continue to run.
        """
        threshold = 3
        sources = SE.extract(self.image)
        msg = "Source Extractor failed to detect at least {0} sources"
        if len(sources) <= threshold:
            raise ValidationError(msg.format(threshold))

    def solve_image(self):
        """Perform astrometry, write image and extract sources."""
        # TODO : Find a way to limit runtime

        img = self.astrometry.solve()
        if not img: raise ImageFailedError("Unable to correct image coordinates.")
        name = "{object}_{date}_{telescope}_{filter}_cal.fits".format(
            object = self.META['OBJECT'],
            date = self.META['FRACTIONAL_DATE'],
            telescope = self.telescope,
            filter = self.META['FILTER']
            )
        output_dir = os.path.join(self.output_dir,
            '{:%Y%m%d}'.format(self.META['DATETIME']))
        if not os.path.exists(output_dir): mkdir(output_dir)
        self.output_file = os.path.join(output_dir, name)
        img.writeto(self.output_file)
        return SE.extract(img)

    def zeropoint(self, sources):
        threshold = 3
        f = self.META['FILTER']
        cataloged_sources, zp , N = Zeropoint_apass(sources, f)
        if (N == 0) or np.isnan(zp):
            raise ImageFailedError('No stars crossmatched to catalog')
        elif (N < threshold):
            raise ImageFailedError('Not enough stars crossmatched to catalog (%d stars found)'%N)
        return cataloged_sources

    def to_db(self, cataloged_sources):
        raise NotImplementedError

    def run(self, *args, **kwargs):
        try:
            self.validate()
            sources = self.solve_image()
            cataloged_sources = self.zeropoint(s)
            self.to_db(cataloged_sources)
        except ImageFailedError:
            # Handle specific errors
            pass

class ValidationError(Exception):
    pass

# step 0 : Check image
# step 1 : Astrometry <- extract+transform
# step 2 : Save to File <- load
# step 3 : identify sources <- extract + transform
# step 4 : zeropoint <- transform
# step 5 : write to db <- load