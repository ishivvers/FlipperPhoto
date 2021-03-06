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
from __future__ import unicode_literals
from builtins import str

import os
import argparse
import glob

from collections import OrderedDict

from tempfile import mktemp

from astropy.io import fits

from flipp.libs.utils import shMixin, FitsIOMixin
from flipp.conf import settings

SEXCONFPATH = settings.SEXCONFPATH
SEXTRACTORPATH = settings.SEXTRACTORPATH
ASTROMETRYCONF = settings.ASTROMETRYCONF
SOLVEFIELDPATH = settings.SOLVEFIELDPATH
TELESCOPES = settings.TELESCOPES


class Astrometry(shMixin, FitsIOMixin):

    cmd = SOLVEFIELDPATH  # For shMixin
    required_config_keys = ("H", "L",)  # For FitsIOMixin
    timeout = 60

    def __init__(self, fp_or_buffer, telescope=None):
        """Runs atrometry on a single fits file/image.

        Parameters
        ----------
        fp_or_buffer : str, astropy.HDUList
            filepath to image or astropy fits image
        telescope_config : str
            'kait', 'nickel' or user specified config
        """
        name, path, image = self._parse_input(fp_or_buffer)
        telescope = telescope or self.get_telescope(image[0].header)
        telescope_config = self._parse_telescope_config(
            telescope, 'ASTROMETRY_OPTIONS')
        self.name = name
        self.path = path
        self.image = image
        self.telescope = telescope_config
        self.last_cmd = None
        self.success = False

    @property
    def defaults(self):
        default_values = (("u", "arcsecperpix"),  # --scale-units
                          ('b', ASTROMETRYCONF),  # --backend-config
                          ('t', 2),  # --tweak-order
                          ('O', None),  # --overwrite
                          ('-no-plots', None),  # --no-plots
                          ('2', None),  # --no-fits2fits
                          ("3", self.image[0].header["RA"].strip()),  # --ra
                          ("4", self.image[0].header["DEC"].strip()),  # --dec
                          ("5", 0.3),  # --radius
                          ("L", self.telescope['L']),  # --scale-low
                          ("H", self.telescope['H']),  # --scale-high
                          ("D", os.path.dirname(os.path.abspath(self.path))),  # --dir
                          ("N", mktemp(prefix="SOLVED-",
                                       suffix="%s" % (self.name))),  # --new-fits
                          ("-sextractor-path", SEXTRACTORPATH),
                          )
        return OrderedDict(default_values)

    def get_output_path(self, config_dict=None):
        if not config_dict:
            config_dict = dict(self.defaults)
        return config_dict['N'] or config_dict['--new-fits'] or None

    def solve(self, *args, **kwargs):
        """Run astrometry on given file input.

        Note
        ----
        Refer to man-page
        """
        args = self.update_args([self.path], args)
        options = self.update_kwargs(self.defaults, kwargs)
        outpath = self.get_output_path(options)
        self.outpath = outpath
        self.last_cmd = self.configure(*args, **options)
        output = self.sh(*args, **options)
        # Delete all temporary files
        tempfiles = glob.glob('{}*'.format(os.path.splitext(self.path)[0]))
        for f in tempfiles:
            os.remove(f)
        if os.path.exists(outpath):
            self.success = True
            return fits.open(outpath)
        else:
            self.success = False


def flippsolve():
    """Console script entry-point for flipp."""
    parser = argparse.ArgumentParser(description='Run astrometry on a file'
                                     ' or directory and send to an output directory.', )

    parser.add_argument('file', metavar="input file(s)", type=str,
                        nargs=1, help='Filepath or directory to fits')
    parser.add_argument('telescope', metavar='telescope config',
                        choices=TELESCOPES.keys(), nargs=1,
                        help='One of {0}'.format(' '.join(TELESCOPES.keys())))
    parser.add_argument('-o', '--output-dir', metavar="output directory", type=str, nargs=1, help="Filepath or directory to put outputs.",
                        dest='output_dir', default='.')
    args = parser.parse_args()

    files = glob.iglob(*args.file)

    for f in files:
        solver = Astrometry(f, args.telescope)
        img = solver.solve(dir=args.output_dir)
        if not img:
            continue
        os.rename(img.filepath, '{0}-SOLVED.fits'.format(solver.name))
