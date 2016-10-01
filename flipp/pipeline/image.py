# -*- coding:utf-8 -*-

from __future__ import unicode_literals

import os
import errno
import logging
import numpy as np

from datetime import datetime, timedelta
from glob import glob

from flipp.libs.sextractor import Sextractor
from flipp.libs.astrometry import Astrometry
from flipp.libs.zeropoint import Zeropoint_apass
from flipp.libs.utils import FitsIOMixin, FileLoggerMixin, mkdir

from flipp.libs import julian_dates

SE = Sextractor()

logger = logging.getLogger(__name__)

class ImageFailedError(Exception):
    """Simple pipeline error; raised when nothing is wrong
    but an image is bad.
    """
    pass

class ValidationError(Exception):
    pass

class ImageParser(FitsIOMixin, FileLoggerMixin, object):

    def __init__(self, input_image, output_dir, telescope=None):
        name, path, images = self._parse_input(input_image)
        self.name = name
        self.file = path
        self.image = images
        self.header = self.image[0].header
        self.telescope = telescope
        self.astrometry = Astrometry(self.image, self.telescope)
        self.output_dir = os.path.join(output_dir,
            '{:%Y%m%d}'.format(self.META['DATETIME']))
        mkdir(self.output_dir)
        self._set_log_conf()

    def __str__(self):
        return str(unicode(self))

    def __unicode__(self):
        templ = "{object}_{date}_{telescope}_{filter}"

    def _set_log_conf(self):
        """TEMPORARY.  Eventually we want dynamic runtime config."""
        self.LOGGER_NAME = self.name
        self.LOGGER_LEVEL = logging.INFO
        self.LOGGER_FILE = os.path.join(
            self.output_dir,
            "flipp_{}.log".format(self.output_dir.split('/')[-1])
            )
        self.logger

    @property
    def META(self):
        if not hasattr(self, '_M'):
            t = unicode(self.telescope)[0].lower()

            # ==============================================================
            # TEMPORARY : Ultimately want this to be "smart" or input-driven
            # ==============================================================
            HEADERMAPS = { 'FILTER' : 'FILTERS', 'DATE' : 'date-obs',
                'TIME' : 'ut', 'OBJECT' : 'object'}
            # ==============================================================
            H = {k : self.header[v].strip() \
                for k, v in HEADERMAPS.iteritems() if self.header.get(v)}

            dt = "{0} {1}".format(H['DATE'], H['TIME'].split('.')[0])
            H['DATETIME'] = datetime.strptime(dt, "%d/%m/%Y %H:%M:%S")
            H['FRACTIONAL_DATE'] = '{:%Y%m%d}{}'.format(H['DATETIME'],
                '{:.4f}'.format(timedelta(
                    hours = H['DATETIME'].hour,
                    minutes = H['DATETIME'].minute,
                    seconds = H['DATETIME'].second).total_seconds()/(60.*60.*24.)).lstrip('0'))
            H['MJD'] = julian_dates.julian_date(
                    *map( lambda x : getattr(H['DATETIME'], x),
                        ['year', 'month', 'day', 'hour', 'minute', 'second']))
            H['INSTRUMENT'] = self.telescope
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
        if not img:
            raise ImageFailedError("Unable to correct image coordinates .")

        self.logger.info("Successfully performed astrometry on %(img)s",
            {"img" : self.file})
        name = "{object}_{date}_{telescope}_{filter}_cal.fits".format(
            object = self.META['OBJECT'],
            date = self.META['FRACTIONAL_DATE'],
            telescope = self.telescope,
            filter = self.META['FILTER']
            )
        output_file = os.path.join(self.output_dir, name)
        with open(output_file, 'w') as f:
            img.writeto(f)

        return SE.extract_image(img)

    def zeropoint(self, sources):
        threshold = 3
        f = self.META['FILTER']
        cataloged_sources, zp , N = Zeropoint_apass(sources, f)
        if (N == 0) or np.isnan(zp):
            raise ImageFailedError('No stars crossmatched to catalog')
        elif (N < threshold):
            raise ImageFailedError('Not enough stars crossmatched to catalog (%d stars found)'%N)
        return cataloged_sources

    def run(self, *args, **kwargs):
        try:
            self.validate()
            sources = self.solve_field()
            cataloged_sources = self.zeropoint(sources)
            return cataloged_sources
        except ImageFailedError as e:
            self.logger.error("%(img)s encountered an error %(e)s",
                {"img" : self.file, "e" : unicode(e)})
        except Exception as e:
            # Handle specific errors
            self.logger.exception(e)
