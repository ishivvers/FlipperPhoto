# -*- coding : utf-8 -*-

import os
import re

from tempfile import mktemp

from astropy.io.fits import hdu
from astropy.table import Table

from flipp.libs.utils import ShellCmd, IMI
from conf import ASTROMETRYCONFPATH

class BaseAstrometry(IMI, ShellCmd):

    pixscale=0.
    pixscaleL=0.
    pixscaleH=0.
    searchradius=0. #in degree
    width=0 #image width in pixel
    height=0 #image height in pixel

    cmd = "solve-field"

    def set_defaults(self, fp_or_buffer):
        options = {"3" : header['RA'],
        "4" : header["DEC"],
        "5" : self.searchradius,
        "-scale-units" : "arcsecperpix",
        "L" : self.pixscaleL,
        "H" : self.pixscaleH,
        "D" : self.getimgdir(fp_or_buffer),
        "b" : DEFAULT_CONF,
        "t" : "1",}
        args = ("O", "p", "y", "2")
        return args, options

    def astrometry(self, filepath_or_buffer, *args, **kwargs):
        args_default, options_default = self.set_defaults(filepath_or_buffer)
        args = self.update_args(args_default, args)
        options = self.update_kwargs(options_default, **kwargs)
        self.run(filepath_or_buffer, *args, **options)

        # Get output file here, ask Isaac what outputs are exactly
        # Having trouble running astrometry on this machine.

class KaitConfig(BaseAstrometry):

    pixscale=0.7965
    pixscaleL=0.79
    pixscaleH=0.80
    searchradius=0.3
    width=500
    height=500

class NickleConfig(BaseAstrometry):

    pixscale=0.37088
    pixscaleL=0.36
    pixscaleH=0.38
    searchradius=0.3 #in degree
    width=1024 #image width in pixel
    height=1024#image height in pixel

