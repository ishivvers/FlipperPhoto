# -*- coding : utf-8 -*-
"""
Astrometry applies a correction to coordinates in an image.
This is done by searching for known objects in the image and then calculating
coordinate information based on input telescope characteristics.

This module provides a python interface for the astrometry.net software.
Host machine must have a astrometry.net installation for this to work.
"""

import os
import re

from tempfile import mktemp

from astropy.io import fits

from flipp.libs.utils import ShellCmd
from conf import SEXCONFPATH

DEFAULT_CONF = "/usr/local/astrometry/etc/astrometry.cfg"
"""A version of this with reasonable defaults ought to be
put under version control in this repository.  Let this be
temporary for now."""

class ConfigurationError(Exception):

    pass

class Astrometry(ShellCmd, object):

    cmd = "solve-field" # cmd attribute for ShellCmd mixin

    required_config_keys = ("pixscaleL",
        "pixscaleH",)

    def __init__(self, fp_or_buffer, telescope_config):
        """
        We want to be able to feed in either a filepath or a pyfits
        object.  In either case, we want some representation of where
        the actual image on disk is, and to never actually write on top
        or over that image.
        """
        name, path, image = self.__parse_input(fp_or_buffer)
        telescope_config = self.__parse_telescope_config(telescope_config)
        self.name = name
        self.path = path
        self.image = image
        self.telescope = telescope_dict

    def __parse_input(self, obj, inplace=False):
        """Sets instance attributes based on input type.

        If obj is string-like, assume it is a filepath, and open it as an
        astropy HDUList.

        If obj is already an astropy HDUList, stay agnostic about origin of
        file on disk, and create a temp file for it. This is potentially
        very slow, but ensures that original images are never written over.
        """
        if isinstance(obj, basestring):
            # Handle filepaths
            path = obj
            try:
                image = fits.open(obj)
            except IOError:
                self.image = ZCat.open(obj)
            name = os.path.split(path)[1]

        elif isinstance(obj, fits.hdu.hdulist.HDUList):
            # or isinstance(obj, fits.hdu.image.PrimaryHDU):
            # Add handling for this if we want to pass in a non-HDUList object
            image = obj
            fp = obj.filename()
            if inplace and fp:
                path = fp
            else:
                z = mktemp(suffix=".fits")
                obj.writeto(z)
                path = z
            if fp:
                name = os.path.split(fp)[1]
            else:
                name = os.path.split(path)[1]

        else:
            # Aggressive type-checking for unhandled inputs
            excp = ("Unparseable object type %s.  Obj must be a filepath or"
                "astropy fits.open object.") %(type(obj))
            raise TypeError(excp)

        return name, path, image

    def __parse_telescope_config(self, obj):
        if isinstance(obj, basestring):
            # Assume someone has set up a dictionary in conf.py
            try:
                config = dict(conf['TELESCOPES'][obj])
            except AttributeError as e:
                excp = "'%s' is not configured in TELESCOPES configuration."
                raise ConfigurationError(excp %(obj))
        elif isinstance(obj, dict):
            config = dict(obj)
        else:
            excp = "Telescope Configuration must be one of %s or dictionary."
            preset = list(conf['TELESCOPES'].keys())
            raise TypeError(excp %(', '.join(['"%s"' %(x) for x in preset])))

        self.validate_config(config)
        return config

    def validate_telescope_config(self, d):
        """Checks for required keys.

        Future iterations should also do some type-checking and
        check that values are reasonable.
        """
        for k in self.required_config_keys:
            if k not in d:
                excp = "Improperly configured telescope.  Missing %s."
                raise ConfigurationError(excp %(k))
            else: pass

    @property
    def defaults(self):
        default_values = {"-scale-units" : "arcsecperpix",
            '-backend-config' : DEFAULT_CONF,
            '-tweak-order' : 2,
            '-overwrite' : '',
            '-no-plots' : '',
            '-use-sextractor' : '',
            '-sextractor-path' : '"%s%"' %(SEXPATH),
            "-ra" : self.image[0].header["RA"],
            "-dec" : self.image[0].header["DEC"],
            "-radius" : 0.3,
            "-scale-low" : self.telescope['pixscaleL'],
            "-scale-high" : self.telescope['pixscaleH'],
            "-dir" : os.path.dirname(os.path.abspath(self.path)),
            "-new-fits" : mktemp(suffix=".fits",
                prefix = "SOLVED-%s" %(self.name)),
            }
        return default_values

    def get_output(self, config_dict):
        filedir = config_dict['-dir']
        filename = config_dict['-new-fits']
        return os.path.join(filedir, filename)

    def solve(self, *args, **kwargs):
        args = self.update_args([self.path], args)
        options = self.update_kwargs(self.defaults, kwargs)
        outpath = self.output(options)
        output = self.run(*args, **options)
        # We need to parse this output to determine whether or not
        # astrometry actually ran.
        return output