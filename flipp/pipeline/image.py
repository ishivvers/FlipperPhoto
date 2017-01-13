# -*- coding:utf-8 -*-

from __future__ import unicode_literals

import os
import errno
import logging
import numpy as np
import matplotlib.pyplot as plt

from astropy.io import fits
from datetime import datetime, timedelta
from glob import glob

from flipp.libs.sextractor import Sextractor
from flipp.libs.astrometry import Astrometry
from flipp.libs.zeropoint import Zeropoint_apass
from flipp.libs.utils import FitsIOMixin, FileLoggerMixin, mkdir
from flipp.libs.fileio import plot_one_image

from flipp.libs import julian_dates
from flipp.conf import settings

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

    def __init__(self, input_image, output_dir=None, telescope=None):
        name, path, image = self._parse_input(input_image)
        self.name = name
        self.file = path
        self.image = image
        # Preprocessing?  see META
        self.header = self.image[0].header
        self.telescope = telescope
        self.astrometry = Astrometry(self.image, self.telescope)
        self.output_root = output_dir or settings.OUTPUT_ROOT
        self.output_dir = os.path.join(
                            self.output_root,
                            '{:%Y%m%d}'.format(self.META['DATETIME'])
                        )
        self.output_file = None # Filled in at solve_field
        mkdir(self.output_dir)
        self.sources = None
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
            #
            # Note: the fits header keyword 'datid' is present for KAIT
            #  images, but not in Nickel ones.  Weikang requests that we use
            #  the filename of the original image, which should be encoded
            #  in the filename of the input file like the regex "d\d{3}".
            #  For example, the string "d123" or "d237".
            # ==============================================================
            HEADERMAPS = { 'FILTER' : 'FILTERS', 'DATE' : 'date-obs',
                'TIME' : 'ut', 'OBJECT' : 'object', 'DATID' : 'datid' }
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
                        ['year', 'month', 'day', 'hour', 'minute', 'second'])) - 2400000.5
            H['INSTRUMENT'] = self.telescope
            H['OBJECT'] = H['OBJECT'].replace('_','-').replace(' ','-')
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
        name = "{object}_{date}_{telescope}_{filter}_c.fit".format(
            object = self.META['OBJECT'],
            date = self.META['FRACTIONAL_DATE'],
            telescope = self.telescope,
            filter = self.META['FILTER']
            )
        output_file = os.path.join(self.output_dir, name)

        with open(output_file, 'w') as f:
            img.writeto(f)
            self.output_file = output_file
            img = fits.open(output_file)
            os.remove(self.astrometry.outpath)  # This always exists if solve has been run
        return img

    def extract_stars(self, img, *args, **kwargs):
        return SE.extract_stars(img, *args, **kwargs)

    def zeropoint(self, sources):
        threshold = 3
        f = self.META['FILTER']
        cataloged_sources, zp , N = Zeropoint_apass(sources, f)
        if (N == 0) or np.isnan(zp):
            raise ImageFailedError('No stars crossmatched to catalog')
        elif (N < threshold):
            raise ImageFailedError('Not enough stars crossmatched to catalog (%d stars found)'%N)
        return cataloged_sources

    def diagnostic_plots(self, *args, **kwargs):
        """Create a few quick plots of the sources identified,
        the background, et cetera, for given image.
        """
        img = self.solve_field()
        stellar_sources = self.extract_stars( img, *args, **kwargs )
        all_sources = SE.extract( img )

        fig0 = plot_one_image( self.image, title='Input Image' )
        # mark all sources identified
        plt.scatter( all_sources['X_IMAGE_DBL'], all_sources['Y_IMAGE_DBL'],
                     c='firebrick', marker='x', s=50 )

        fig1 = plot_one_image( SE.chk_bkgrnd, title='Background' )
        fig2 = plot_one_image( SE.chk_objects, title='Objects', normalize='log' )
        # mark all sources labeled as stars
        plt.scatter( stellar_sources['X_IMAGE_DBL'], stellar_sources['Y_IMAGE_DBL'],
                     c='firebrick', marker='x', s=50 )
        plt.show()

    def run(self, *args, **kwargs):
        try:
            self.validate()
            sources = self.extract_stars( self.solve_field() )
            cataloged_sources = self.zeropoint(sources)
            self.sources = cataloged_sources
            os.remove(self.file)
            return cataloged_sources
        except ImageFailedError as e:
            self.logger.error("%(img)s encountered an error %(e)s",
                {"img" : self.file, "e" : unicode(e)})
        except Exception as e:
            # Handle specific errors
            self.logger.exception(e)
        finally:
            if os.path.exists(self.file):
                os.remove(self.file)
