# -*- encoding : utf-8 -*-
"""Python wrapper for Sextractor, with python-friendly config."""
import os
import re
import tempfile

from fabric.api import local

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
            d = dict(filter(None, map(self._parse_sex_option, f.readlines())))
        return d

    def _parse_sex_option(self, s):
        """Returns either a null or 2-tuple of available arguments to feed into sextractor."""
        match = self.option_re.match(s)
        if match:
            parts = re.split('\s+', s, 1)
            return match.group(), self.value_re.match(parts[1]).group()
        return tuple()

class sextractor(ShellCmd):
    """Sextractor wrapper with config built in."""

    cmd = "sextractor"

    def read_default_conf(self):
        raise NotImplementedError

    def extract(self):
        raise NotImplementedError