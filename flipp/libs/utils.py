from fabric.api import local

class ShellCmd(object):
    """Convenience class for shell functions"""

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
        return 

    def run(self, *args, **kwargs):
        cmd = self.configure(*args, **kwargs)
        return local(cmd, capture=True)