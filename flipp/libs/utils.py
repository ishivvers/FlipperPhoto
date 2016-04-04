# -*- coding : utf-8 -*-
import os

from astropy.io.fits import hdu
from astropy.io import fits
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

    Should consider replacing this with argparse and fabric.
    """

    cmd = ""

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
    def configure(cls, *args, **kwargs):
        """."""
        base = str(cls.cmd)
        cmdargs, cmdkwargs = "", ""

        if args:
            cmdargs = ' '.join(args)
        if kwargs:
            pieces = [' '.join([k, '"%s"' %(v)]) for k, v in kwargs.iteritems()]
            cmdkwargs = " ".join(["-%s" %(s) for s in pieces])

        base = " ".join((base, cmdargs, cmdkwargs))
        return base

    @classmethod
    def clean(self):
        """Do nothing by default.  A subclass implementation might
        remove any temporary files, or do some post-processing."""
        pass

    @classmethod
    def run(cls, *args, **kwargs):
        cmd = cls.configure(*args, **kwargs)
        msg = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()
        self.clean()
        return msg

class ZCat(ShellCmd):

    cmd = "zcat"

    @classmethod
    def open(cls, filepath):
        raw = cls.run(filepath)[0]
        hdu = fits.open(StringIO(raw))
        hdu.verify("fix")
        return hdu