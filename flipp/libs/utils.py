# -*- coding : utf-8 -*-
import os

from astropy.io.fits import hdu
from subprocess import Popen, PIPE
from tempfile import mktemp

class ShellCmd(object):
    """Generic bash command wrapper with some option/argument parsing and giving
     a common api to :method:`fabric.api.local` and :method:`fabric.api.run`

    Note
    ----
    This is meant to be subclassed with a :attr:`cmd` value that
    corresponds to a valid bash command.  Commands run remotely may
    contain global side effects such as file creation.  The subclass
    should handle any expected side effects, retriving remote files
    if necessary.
    """

    cmd = ""

    def configure(self, *args, **kwargs):
        """."""
        base = str(self.cmd)
        cmdargs, cmdkwargs = "", ""

        if args:
            cmdargs = ' '.join(args)
        if kwargs:
            pieces = [' '.join([k, '"%s"' %(v)]) for k, v in kwargs.iteritems()]
            cmdkwargs = " ".join(["-%s" %(s) for s in pieces])

        base = " ".join((base, cmdargs, cmdkwargs))
        return base

    def run(self, *args, **kwargs):
        cmd = self.configure(*args, **kwargs)
        return Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()

class IMI(object):
    """In-Memory-Image mixin"""

    def getimgdir(self, filepath_or_buffer):
        f = self.getimgfile(filepath_or_buffer)
        return os.path.dirname(f)

    def getimgfile(self, filepath_or_buffer):
        fp = filepath_or_buffer
        if isinstance(fp, str): return fp
        if isinstance(fp, file): return fp.name
        if isinstance(fp, hdu.hdulist.HDUList) or \
            isinstance(fp, hdu.image.PrimaryHDU):
            z = mktemp(suffix=".fits")
            fp.writeto(z)
            return z