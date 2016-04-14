# -*- coding , utf-8 -*-
"""
Astrometry applies a correction to coordinates in an image.
This is done by searching for known objects in the image and then calculating
coordinate information based on input telescope characteristics.

This module provides a python interface for the astrometry.net software.
Host machine must have a astrometry.net installation for this to work.

Note
----

Depending on the longevity of this piece of software, it is worth
noting that further development should be done in such a way that
photutils can be easily integrated as a drop-in replacement when
the photutils project is mature enough to replace astrometry.

It should be mentioned that a lot of the code design was derived
from studying the structure of the LEMON project.
"""

import os
import re

from collections import OrderedDict

from tempfile import mktemp

from astropy.io import fits

from flipp.libs.utils.shell import shMixin, FitsIOMixin
from conf import SEXCONFPATH

DEFAULT_CONF = "/usr/local/astrometry/etc/astrometry.cfg"
"""A version of this with reasonable defaults ought to be
put under version control in this repository.  Let this be
temporary for now."""


class Astrometry(shMixin, FitsIOMixin):

    cmd = "solve-field" # For shMixin
    required_config_keys = ("pixscaleL",
        "pixscaleH",) # For FitsIOMixin

    def __init__(self, fp_or_buffer, telescope_config):
        """
        We want to be able to feed in either a filepath or a pyfits
        object.  In either case, we want some representation of where
        the actual image on disk is, and to never actually write on top
        or over that image.
        """
        name, path, image = self._parse_input(fp_or_buffer)
        telescope_config = self._parse_telescope_config(telescope_config)
        self.name = name
        self.path = path
        self.image = image
        self.telescope = telescope_config
        self.last_cmd = None

    @property
    def defaults(self):
        default_values = (("-scale-units" , "arcsecperpix"),
            ('-backend-config' , DEFAULT_CONF),
            ('-tweak-order' , 2),
            ('-overwrite' , None),
            ('-no-plots' , None),
            ("-ra" , self.image[0].header["RA"]),
            ("-dec" , self.image[0].header["DEC"]),
            ("-radius" , 0.3),
            ("-scale-low" , self.telescope['pixscaleL']),
            ("-scale-high" , self.telescope['pixscaleH']),
            ("-dir" , os.path.dirname(os.path.abspath(self.path))),
            ("-new-fits" , mktemp(suffix=".fits", prefix = "SOLVED-%s" %(self.name))),
            ("-sextractor-path" , "/usr/bin/sextractor"),
            )
        return OrderedDict(default_values)

    def get_output_path(self, config_dict):
        filedir = config_dict['-dir']
        filename = config_dict['-new-fits']
        return os.path.join(filedir, filename)

    def get_solved_img(self, config_dict):
        filedir = config_dict['-dir']
        filename = config_dict['-new-fits']
        fp = os.path.join(filedir, filename)
        with open(fp, 'rb') as fd:
            if ord(fd.read()) != 1:
                raise AstrometryNetUnsolvedField(path)

    def solve(self, *args, **kwargs):
        args = self.update_args([self.path], args)
        options = self.update_kwargs(self.defaults, kwargs)
        outpath = self.get_output_path(options)
        self.last_cmd = self.configure(*args, **options)
        output = self.sh(*args, **options)

        # We need to parse this output to determine whether or not
        # astrometry actually ran.

        # return output #fits.open(outpath)
        if outpath:
            return fits.open(outpath)