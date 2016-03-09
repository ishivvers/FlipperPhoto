from subprocess import Popen, PIPE

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
        base = self.cmd
        cmdargs, cmdkwargs = "", ""

        if args:
            cmdargs = ' '.join(args)
        if kwargs:
            pieces = [' '.join(k, v) for k, v in kwargs.iteritems()]
            cmdkwargs = ' -'.join(pieces)
            
        base = "%s %s %s" %(base, cmdargs, cmdkwargs)
        return base

    def run(self, *args, **kwargs):
        cmd = self.configure(*args, **kwargs)
        return Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE).communicate()