# -*- coding: utf-8 -*-
from __future__ import unicode_literals

"""
Lazy settings object inspired by Django's configuration.  Allows local overrides
by setting the "FLIPP_CONF" environment variable or hardcoding a "local.py" in
the same directory as "flipp/conf"
"""

import os
import imp
import warnings

from . import global_settings


class LazySettings(object):
    """A django-esque lazy settings object, except a little dumber."""

    def __init__(self):
        self.__registry__ = {}
        self.__configure()

    def __configure(self):
        self.__setup(global_settings)
        try:
            settings_file = os.environ.get('FLIPP_CONF',
                os.path.join(global_settings.PROJECT_DIR, "conf", "local.py"))
            local_settings = imp.load_source('local_settings', settings_file)
            self.__setup(local_settings)
        except Exception as e:
            warnings.warn(unicode(e))

    def __setup(self, module):
        for setting in dir(module):
            if setting.isupper():
                self.__registry__[setting] = module

    def __getattr__(self, name):
        """We maintain a registry of settings with the correct module to find them in.
        Note that ``__getattr__`` is only called if ``__getattribute__`` fails, meaning
        once we set an instance attribute here, it never gets called again.
        """
        if name in self.__registry__:
            module = self.__registry__[name]
            setattr(self, name, getattr(module, name))
        return getattr(self, name)

settings = LazySettings()
