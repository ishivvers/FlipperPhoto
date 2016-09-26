# -*- coding:utf-8 -*-

from __future__ import unicode_literals
from builtins import str

import os
import errno
import logging
import numpy as np

from datetime import datetime, timedelta
from glob import glob

from flipp.libs.sextractor import Sextractor
from flipp.libs.astrometry import Astrometry
from flipp.libs.zeropoint import Zeropoint_apass
from flipp.libs.utils import FitsIOMixin

SE = Sextractor()

class ImageFailedError(Exception):
    """Simple pipeline error; raised when nothing is wrong
    but an image is bad.
    """
    pass

class ImageParser(FitsIOMixin, object):

    def __init__(self, input_image, output_dir, telescope=None):
        self.output_dir = output_dir
        name, path, images = self._parse_input(input_image)
        self.file = path
        self.image = images
        self.header = self.image[0].header
        self.telescope = telescope
        self.astrometry = Astrometry(self.image, self.telescope)

    def __str__(self):
        return str(unicode(self))

    def __unicode__(self):
        templ = "{object}_{date}_{telescope}_{filter}"

    @property
    def META(self):
        if not hasattr(self, '_M'):
            t = str(self.telescope)[0].lower()
            # ==============================================================
            # TEMPORARY : Ultimately want this to be "smart" or input-driven
            # ==============================================================
            HEADERMAPS = { 'FILTER' : 'FILTERS', 'DATE' : 'date-obs',
                'TIME' : 'ut', 'OBJECT' : 'object'}
            H = {k : self.header[v].strip() \
                for k, v in HEADERMAPS.iteritems() if self.header.get(v)}
            # ==============================================================
            dt = "{0} {1}".format(H['DATE'], H['TIME'].split('.')[0])
            H['DATETIME'] = datetime.strptime(dt, "%d/%m/%Y %H:%M:%S")
            H['FRACTIONAL_DATE'] = '{:%Y%m%d}{}'.format(H['DATETIME'],
                '{:.4f}'.format(timedelta(
                    hours = H['DATETIME'].hour,
                    minutes = H['DATETIME'].minute,
                    seconds = H['DATETIME'].second).total_seconds()/(60.*60.*24.)).lstrip('0'))
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

    def solve_field(self):
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

    def parse(self, *args, **kwargs):
        try:
            self.validate()
            sources = self.solve_field()
            cataloged_sources = self.zeropoint(sources)
            return cataloged_sources
        except ImageFailedError:
            # Handle specific errors
            pass

class SourceMatcher(object):

    catalog = conf.DB_URL

    @property
    def engine(self):
        if not self._engine:




class ValidationError(Exception):
    pass

# step 0 : Check image
# step 1 : Astrometry <- extract+transform
# step 2 : Save to File <- load
# step 3 : identify sources <- extract + transform
# step 4 : zeropoint <- transform
# step 6 : find match in db
# step 6a. : If match, add an observation to said object
