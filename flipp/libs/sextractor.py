# -*- encoding : utf-8 -*-
"""Python wrapper for Sextractor, with python-friendly config."""
import os
import re
import warnings
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


SEXTRACTOR_OPTION_RE = re.compile("[A-Za-z_]+(?=\s)")
SEXTRACTOR_VALUE_RE = re.compile("\S*(?=\s)")
SEXTRACTOR_SECTION_RE = re.compile("\#(\-+)(\w|\s)+")


class Sextractor(shMixin, FitsIOMixin):
    """Sextractor wrapper with config built in."""

    cmd = SEXTRACTORPATH

    def __init__(self, fp_or_buffer, telescope=None):
        """Runs source extractor on a single fits file/image.

        Parameters
        ----------
        fp_or_buffer : str, astropy.HDUList
            filepath to image or astropy fits image
        telescope_config : str
            'kait', 'nickel' or user specified config
        """
        self.name, self.path, self.image = self._parse_input(fp_or_buffer)
        self.telescope = telescope or self.get_telescope(self.image[0].header)
        telescope_config = self._parse_telescope_config(self.telescope,
                                                        "SEXTRACTOR_OPTIONS")
        self.last_cmd = None
        self.success = False
        self.defaults = telescope_config

    def _sexconf2dict(self, path=default_sex):
        with open(path) as f:
            d = dict(
                filter(None, map(self._parse_sextractor_option, f.readlines())))
        return d

    def _parse_sextractor_option(self, s):
        """Returns either a null or 2-tuple of available arguments to feed into sextractor."""
        match = SEXTRACTOR_OPTION_RE.match(s)
        if match:
            parts = re.split('\s+', s, 1)
            return match.group(), \
                '%s' % (SEXTRACTOR_VALUE_RE.match(parts[1]).group())
        return tuple()

    @property
    def defaults(self):
        return dict(self._defaults)

    @defaults.setter
    def defaults(self, value):
        #defaults = self._sexconf2dict()
        defaults = dict(value)
        if "CATALOG_NAME" not in defaults:
            defaults.update(CATALOG_NAME = mkstemp(suffix=".txt", prefix="CATALOG_")[1])
        if "CHECKIMAGE_NAME" not in defaults:
            defaults.update({
                "CHECKIMAGE_NAME": "%s,%s" % (
                    mkstemp(suffix=".fits", prefix="CHECK-OBJECTS_")[1],
                    mkstemp(suffix=".fits", prefix="CHECK-BKGRND_")[1])})
        defaults.update({
                    "CHECKIMAGE_TYPE": "OBJECTS,BACKGROUND",  # Objects
                    "FILTER_NAME": default_filter,
                    "PARAMETERS_NAME": default_param,
                    "STARNNW_NAME": default_nnw,
                    "c": default_sex,
                    })

        self._defaults = defaults

    def extract(self, flag_filter=True, *args, **kwargs):
        """Run source-extractor (sextractor) on the given image.
        If flag_filter == True, return only sources with FLAGS == 0

        Note
        ----

        Return
        ------

        """
        options = self.defaults
        options.update(kwargs)
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

        with warnings.catch_warnings():
            warnings.simplefilter('ignore')
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

    def extract_stars(self, *args, **kwargs):
        """Extract sources on an image, attempt to classify
        each source as star/not-star, and return only those
        sources labeled a star.
        """
        thresh = kwargs.pop('thresh', 0.5)  # the threshold applied to
        #  source extactor's CLASS_STAR
        sources = self.extract(*args, **kwargs)
        pix_scale = 0.8  # this telescope-dependant number should be
        #  stored along with other parameters of the
        #  telesope, probably in global config file.
        seeing = np.median(pix_scale * sources['FWHM_IMAGE'])
        kwargs.update({"SEEING_FWHM": seeing})
        sources = self.extract(filepath_or_buffer, *args, **kwargs)
        return sources[sources['CLASS_STAR'] >= thresh]
