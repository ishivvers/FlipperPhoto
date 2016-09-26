# -*- coding:utf-8 -*-
"""
A lot of photometry related code has yet to be ported and will most
probably never be ported to a proper (and performant) python library.
The purpose of this module is to provide an API for the rest of the app
to interact with external programs, porting over bash calls to their
python analogies of argument lists and keyword arguments.
"""

import os
import shutil
import logging

from astropy.io import fits
from subprocess import Popen, PIPE

from tempfile import mktemp
from flipp.conf import settings

TELESCOPES = settings.TELESCOPES

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
        stdout, stderr = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
        return cls.process_cmd(stdout, stderr)

class FitsIOMixin(object):
    """Utilities for proxying .fits files as astropy HDUList objects."""

    required_config_keys = tuple()

    def _parse_input(self, obj, inplace=False):
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
            name = os.path.split(obj)[1]

            path = mktemp(prefix="COPY-{0}".format(os.path.splitext(name)[0]),
                suffix=".fits")
            image.writeto(path, output_verify="silentfix")

        elif isinstance(obj, fits.hdu.hdulist.HDUList):
            # Add handling for this if we want to pass in a non-HDUList object
            image = obj
            fp = obj.filename()
            if inplace and fp:
                path = fp
            else:
                z = mktemp(suffix=".fits")
                obj.writeto(z, output_verify="silentfix")
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

class LoggerMixin(object):
    """Create class-instance specific log, uses conf.LOGGING as default."""

    @property
    def logger(self):
        if not hasattr(self, '_logger'):

        return self._logger
