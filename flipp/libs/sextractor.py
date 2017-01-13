# -*- encoding : utf-8 -*-
"""Python wrapper for Sextractor, with python-friendly config."""
import os
import re
import numpy as np
import matplotlib.pyplot as plt

from tempfile import mkstemp

from astropy.io.fits import hdu
from astropy.table import Table

from flipp.libs.fileio import plot_one_image
from flipp.libs.utils import shMixin, FitsIOMixin
from flipp.conf import settings


SEXCONFPATH = settings.SEXCONFPATH
SEXTRACTORPATH = settings.SEXTRACTORPATH
# ================
# DEVELOPMENT NOTE
# ================
# WE SHOULD CREATE A /TMP/ FOR EACH OF THESE AS WELL WITH USER-SPECIFIED
# CONFIGURATION.  THERE OUGHT TO BE A CONFIG METHOD FOR EACH OF THESE
# ALTERNATIVELY, YOU COULD STAY AGNOSTIC AND ASK FOR USER-SPECIFIED FILE
# IMPLEMENTATION WISE, THIS WOULD REQUIRE HAVING THE ABILITY TO DO THE OPPOSITE
# OF ``sextractorConfig._sexconf2dict``.  THIS IS TEDIOUS SO DO IT LATER.

default_sex = os.path.join(SEXCONFPATH, "default.sex")
default_param = os.path.join(SEXCONFPATH, "default.param")
default_filter = os.path.join(SEXCONFPATH, "gauss_3.0_5x5.conv")
default_nnw = os.path.join(SEXCONFPATH, "default.nnw")


class sextractorConfig(object):

    option_re = re.compile("[A-Za-z_]+(?=\s)")
    value_re = re.compile("\S*(?=\s)")
    section_re = re.compile("\#(\-+)(\w|\s)+")

    def _sexconf2dict(self, path=default_sex):
        with open(path) as f:
            d = dict(
                filter(None, map(self._parse_sextractor_option, f.readlines())))
        return d

    def _parse_sextractor_option(self, s):
        """Returns either a null or 2-tuple of available arguments to feed into sextractor."""
        match = self.option_re.match(s)
        if match:
            parts = re.split('\s+', s, 1)
            return match.group(), \
                '"%s"' % (self.value_re.match(parts[1]).group())
        return tuple()


class Sextractor(sextractorConfig, shMixin, FitsIOMixin):
    """Sextractor wrapper with config built in."""

    cmd = SEXTRACTORPATH

    def set_defaults(self):
        """Sets default settings for running sextractor."""

        D = {"CATALOG_NAME": mkstemp(suffix=".txt", prefix="CATALOG_")[1],  # Catalog
             "CHECKIMAGE_TYPE": "OBJECTS,BACKGROUND",  # Objects
             "CHECKIMAGE_NAME": "%s,%s" % (mkstemp(suffix=".fits", prefix="CHECK-OBJECTS_")[1], mkstemp(suffix=".fits", prefix="CHECK-BKGRND_")[1]),
             "FILTER_NAME": default_filter,
             "PARAMETERS_NAME": default_param,
             "STARNNW_NAME": default_nnw,
             "c": default_sex,
             }
        return D


    def extract(self, filepath_or_buffer, flag_filter=True, *args, **kwargs):
        """Run source-extractor (sextractor) on the given image.
        If flag_filter == True, return only sources with FLAGS == 0

        Note
        ----


        Return
        ------

        """
        options = self.set_defaults()
        options.update(kwargs)
        name, path, image = self._parse_input(filepath_or_buffer)
        self.path = path
        self.last_cmd = self.configure(*args, **options)
        output = self.sh(self.path, *args, **options)

        # ===========================================================
        # Keep track of the check images
        chk_imgs = options.get("CHECKIMAGE_NAME").split(",")
        for c in chk_imgs:
            if 'OBJECTS' in c:
                self.chk_objects = c
            elif 'BKGRND' in c:
                self.chk_bkgrnd = c
        # ===========================================================

        catalog = Table.read(options.get("CATALOG_NAME"),
                             format="ascii.sextractor")

        # Cleanup tmp files
        """
        ORIGINALLY, there were plans to refine some kind of output using these.
        Due to practical time constraints, we just delete them for now.
        """
        os.remove(options.get("CATALOG_NAME"))
        os.remove(self.chk_objects)
        os.remove(self.chk_bkgrnd)
        os.remove(self.path)
        if flag_filter:
            catalog = catalog[catalog['FLAGS'] == 0]
        return catalog

    def extract_stars(self, filepath_or_buffer, *args, **kwargs):
        """Extract sources on an image, attempt to classify
        each source as star/not-star, and return only those
        sources labeled a star.
        """
        thresh = kwargs.pop('thresh', 0.5)  # the threshold applied to
        #  source extactor's CLASS_STAR
        sources = self.extract(filepath_or_buffer, *args, **kwargs)
        pix_scale = 0.8  # this telescope-dependant number should be
        #  stored along with other parameters of the
        #  telesope, probably in global config file.
        seeing = np.median(pix_scale * sources['FWHM_IMAGE'])
        kwargs.update({"SEEING_FWHM": seeing})
        sources = self.extract(filepath_or_buffer, *args, **kwargs)
        return sources[sources['CLASS_STAR'] >= thresh]
