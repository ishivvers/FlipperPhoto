# -*- coding:utf-8 -*-
"""
A lot of photometry related code has yet to be ported and will most
probably never be ported to a proper (and performant) python library.
The purpose of this module is to provide an API for the rest of the app
to interact with external programs, porting over bash calls to their
python analogies of argument lists and keyword arguments.
"""

from __future__ import unicode_literals

import re
import os
import sys
import errno
import logging

from tempfile import mkstemp
from astropy.io import fits
from flipp.conf import settings

if sys.version_info < (3, 3):
    import subprocess32 as subprocess
else:
    import subprocess


TELESCOPES = settings.TELESCOPES
Popen = subprocess.Popen
PIPE = subprocess.PIPE

from flipp.libs.fileio import get_zipped_fitsfile

# We may want to rewrite this to work around fabric
# which will allow remote calls.  Depending on how Isaac views
# this tool being used, we'll stick with a locally-runnable version
# based on subprocess for now
# ---------------------------------
# from fabric.api import local, run
# ---------------------------------

def mkdir(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            pass

class ConfigurationError(Exception):

    pass


class shMixin(object):

    """Generic bash command wrapper with some option/argument parsing.

    This is meant to provide a simple analogy for making bash calls
    with the same syntax as a python function.  Note that certain conventions
    are just that, conventions.  There's no guarantee that the assumed analogy
    will work with the program of interest.

    Note
    ----
    Use this as a Mixin for an object with a :attr:`cmd` attribute.

    Example
    -------

    .. code-block::

        class ls(ShellMixin):

            cmd = "ls"

        ls.run(".")
    """

    cmd = ""
    timeout = None

    @classmethod
    def configure(cls, *args, **kwargs):
        """."""
        base = str(cls.cmd)
        cmdargs, cmdkwargs = "", ""

        if args:
            cmdargs = ' '.join(args)
        if kwargs:
            pieces = [' '.join([k, '"%s"' %(v)]) if v else k for k, v in kwargs.iteritems()]
            cmdkwargs = " ".join(["-%s" %(s) for s in pieces])

        base = " ".join((base, cmdargs, cmdkwargs))
        return base

    @classmethod
    def process_cmd(cls, stdout, stderr):
        """Default behavior is to do no processing."""
        return stdout, stderr

    @classmethod
    def man(cls):
        from fabric.api import local
        local("man {}".format())
        filter(lambda x : x.startswith('-'), map(str.strip, args))

    @classmethod
    def update_args(self, defaults, update_args):
        d = list(defaults)
        for u in update_args:
            if u not in defaults:
                d.append(u)
        return d

    @classmethod
    def update_kwargs(self, defaults, update_kwargs):
        d = dict(defaults)
        d.update(update_kwargs)
        return d

    @classmethod
    def sh(cls, *args, **kwargs):
        cmd = cls.configure(*args, **kwargs)
        stdout, stderr = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate(timeout=cls.timeout)
        return cls.process_cmd(stdout, stderr)


class FitsIOMixin(object):
    """Utilities for proxying .fits files as astropy HDUList objects."""

    required_config_keys = tuple()

    def _parse_input(self, obj):
        """Sets instance attributes based on input type.

        If obj is string-like, assume it is a filepath, and open it as an
        astropy HDUList.

        If obj is already an astropy HDUList, stay agnostic about origin of
        file on disk, and create a temp file for it. This is potentially
        very slow, but ensures that original images are never written over.
        """
        if isinstance(obj, basestring):
            # Handle filepaths
            try:
                image = fits.open(obj)
            except IOError:
                # self.image = ZCat.open(obj)
                image = get_zipped_fitsfile(obj)
            # strip out header commentary cards, which often have
            #  non-ascii characters
            image = self._strip_commentary_cards(image)
            name = os.path.split(obj)[1]
            path = mkstemp(prefix="COPY-{0}".format(os.path.splitext(name)[0]),
                suffix=".fits")[1]
            with open(path, 'w') as f:
                image.writeto(f, output_verify="silentfix+ignore")

        elif isinstance(obj, fits.hdu.hdulist.HDUList):
            # Add handling for this if we want to pass in a non-HDUList object
            image = obj
            fp = obj.filename()
            z = mkstemp(suffix=".fits")[1]
            with open(z, 'w') as f:
                obj.writeto(f, output_verify="silentfix+ignore")
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

    def get_telescope(self, header):
        for h in settings.INSTRUMENT_HEADERS:
            telescope = dict(header).get(h, None)  # Try to get telescope name
            if telescope:  # Try some regex magic
                for t in settings.TELESCOPES:  #.keys()
                    if bool(re.search(t,
                            re.sub("[^A-Za-z]", "", telescope, flags=re.I),
                            flags=re.I)):
                        return t
        raise ValueError("No telescope provided or found.")

    def _parse_telescope_config(self, obj, p=None):

        if isinstance(obj, basestring):
            # Assume someone has set up a dictionary in conf.py
            try:
                config = dict(TELESCOPES[obj])
            except AttributeError as e:
                excp = "'%s' is not configured in TELESCOPES configuration."
                raise ConfigurationError(excp %(obj))
        elif isinstance(obj, dict):
            config = dict(obj)
        else:
            excp = "Telescope Configuration must be one of %s or dictionary."
            preset = list(TELESCOPES.keys())
            raise TypeError(excp %(', '.join(['"%s"' %(x) for x in preset])))
        if p : config = config[p]
        self.validate_telescope_config(config)
        return config

    def _strip_commentary_cards(self, image):
        """Strips non-ASCII commentary cards from fits header;
        sometimes required for commentary cards that do not adhere
        to FITS standard.
        """
        if image[0].header.get('COMMENT') == None:
            # this file does not have comment cards
            return image
        for i,c in enumerate(image[0].header['COMMENT'][:]):
            try:
                c = c.encode('ascii')
            except UnicodeDecodeError:
                image[0].header['COMMENT'][i] = 'Redacted for not being ASCII'
        return image

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

    def save_img(self, img, path_to_output):
        if hasattr(img, "writeto"):
            dirname = os.path.dirname(output_file)
            if not os.path.exists(dirname): mkdir(dirname)
            img.writeto(path_to_output)

class FileLoggerMixin(object):
    """Create class-instance specific log for processes which should generate
    their own filelog.
    """

    @property
    def logger(self):
        return getattr(self, '_logger', self._configure_log())

    def _configure_log(self):

        logger = logging.getLogger(
            getattr(self, "LOGGER_NAME", "standalone_log")
            )
        logger.handlers = []
        logger.setLevel(
            getattr(self, "LOGGER_LEVEL", logging.DEBUG)
            )
        fh = logging.FileHandler(
            getattr(self, "LOGGER_FILE", None) or mkstemp(suffix=".log", prefix=logger.name)[1]
            )
        fh.setFormatter(
            logging.Formatter(
                getattr(self, "LOGGER_FORMAT", "(%(levelname)s) - %(asctime)s ::: %(message)s")
            ))
        logger.addHandler(fh)
        if getattr(self, "LOGGER_CONSOLE", False):
            sh = logging.StreamHandler()
            sh.setFormatter(logging.Formatter(
                getattr(self, "LOGGER_FORMAT", "(%(levelname)s) - %(asctime)s ::: %(message)s")
                ))
            logger.addHandler(sh)
        self._logger = logger
        return logger
