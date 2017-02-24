# -*- coding:utf-8 -*-

from __future__ import unicode_literals

import os
import re
import dateutil
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
        self.telescope = telescope or self.__get_telescope(self.header)
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
        return templ

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
            HEADERMAPS = settings.TELESCOPES[self.telescope]["HEADER_MAPS"]
            H = {k : str(self.header[v]).strip() \
                for k, v in HEADERMAPS.iteritems() if self.header.get(v)}

            # Try to get date and time
            dt = "{0} {1}".format(H['DATE'], H['TIME'].split('.')[0])
            try:
                H['DATETIME'] = datetime.strptime(dt, "%d/%m/%Y %H:%M:%S")
            except ValueError:
                H["DATETIME"] = dateutil.parser.parse(dt, ignoretz=True)
            H['CLEAN_DATE'] = '{:%Y%m%d}'.format(H['DATETIME'])
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

            # Try to get original file number if it exists
            if "DATID" not in H:
                obsnum = re.search("d\d{3}", os.path.splitext(self.name)[0], flags=re.I)
                if obsnum:
                    H["DATID"] = obsnum.group()
                else:
                    H["DATID"] = self.name
            else:
                obsnum = re.search("\d{3}", H["DATID"], flags=re.I)
                if obsnum:
                    obsnum = obsnum.group()
                    H["DATID"] = "d{}".format(obsnum)
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
        img = self.astrometry.solve()
        if not img:
            raise ImageFailedError("Unable to correct image coordinates .")

        self.logger.info("Successfully performed astrometry on %(img)s",
            {"img" : self.name})
        name = "{object}_{date}_{time}_{datid}_{telescope}_{filter}_c.fit".format(
            object = self.META['OBJECT'],
            date = self.META['CLEAN_DATE'],
            time = self.META['TIME'].replace(':',''),
            datid = self.META['DATID'],
            telescope = self.telescope,
            filter = self.META['FILTER']
            )
        output_file = os.path.join(self.output_dir, name)

        with open(output_file, 'w') as f:
            img.writeto(f)
            self.output_file = output_file
            img = fits.open(output_file)
            os.remove(self.astrometry.outpath)  # This always exists if solve has been run
        self.logger.info("Saved wcs-corrected image %(img)s to %(out)s",
            {"img" : self.name, "out" : output_file})
        return img

    def extract_stars(self, img, *args, **kwargs):
        ## because the SE star/galaxy classifications are not trustworthy,
        ##  extract everything for now
        #return SE.extract_stars(img, *args, **kwargs)
        return SE.extract(img, *args, **kwargs)


    def zeropoint(self, sources):
        threshold = 3
        f = self.META['FILTER']
        zp_sources, zp , N = Zeropoint_apass(sources, f)
        if (N == 0) or np.isnan(zp):
            raise ImageFailedError('No stars crossmatched to catalog')
        elif (N < threshold):
            raise ImageFailedError('Not enough stars crossmatched to catalog (%d stars found)'%N)
        return zp_sources

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
            self.sources = self.zeropoint(sources)
            os.remove(self.file)
            return self.sources
        except ImageFailedError as e:
            self.logger.error("%(img)s encountered an error %(e)s",
                {"img" : self.name, "e" : unicode(e)})
        except Exception as e:
            # Handle specific errors
            self.logger.exception(e)
        finally:
            if os.path.exists(self.file):
                os.remove(self.file)
