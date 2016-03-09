# -*- encoding : utf-8 -*-
"""Python wrapper for Sextractor, with python-friendly config."""
import os
import re
from tempfile import mktemp

from flipp.libs.utils import ShellCmd
from conf import SEXCONFPATH

default_sex = os.path.join(SEXCONFPATH, "default.sex")
default_param = os.path.join(SEXCONFPATH, "default.param")

class sextractorConfig(object):

    option_re = re.compile("[A-Za-z_]+(?=\s)")
    value_re = re.compile("\S*(?=\s)")
    section_re = re.compile("\#(\-+)(\w|\s)+")

    def _conf2dict(self, path=default_sex):
        with open(path) as f:
            d = dict(filter(None, map(self._parse_sextractor_option, f.readlines())))
        return d

    def _parse_sextractor_option(self, s):
        """Returns either a null or 2-tuple of available arguments to feed into sextractor."""
        match = self.option_re.match(s)
        if match:
            parts = re.split('\s+', s, 1)
            return match.group(), self.value_re.match(parts[1]).group()
        return tuple()

class sextractor(ShellCmd):
    """Sextractor wrapper with config built in."""

    cmd = "sextractor"

    @property
    def tmpfp(self):
        return 

    def set_defaults(self):
        """Sets default settings for running sextractor."""
        D = {"CATALOG_NAME" : mktemp(".txt"), # Catalog
            "CHECKIMAGE_TYPE" : "OBJECTS,BACKGROUND", # Objects
            "CHECKIMAGE_NAME" : "%s,%s" %(mktemp(".fits"), mktemp(".fits")),
            "c" : "default.sex",
            "PARAMETERS_NAME" : "default.param",
            "FILTER_NAME" : "gauss_3.0_5x5.conv",
            }
        return D

    def fits2disk(self, buffer, fp):
        raise NotImplementedError

    def extract(self, pathname_or_fits, **kwargs):
        """Write to filepath or buffer."""
        options = self.set_defaults()
        options.update(kwargs)
        self.run()
