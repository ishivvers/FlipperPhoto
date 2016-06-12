# -*- coding : utf-8 -*-

from __future__ import unicode_literals
from builtins import str

import requests
import pandas as pd

from StringIO import StringIO

class Client(object):

    host = "https://www.aavso.org/"
    endpoint = "cgi-bin/apass_download.pl"
    __cache = {}
    agent = "UC Berkeley Filippenko Group's Photometry Pipeline"

    @classmethod
    def _build_url(cls, **kwargs):
        url = "{host}/{endpoint}"
        url = url.format(host=cls.host, endpoint=cls.endpoint)
        if kwargs:
            url += "?"
            url += "&".join(["{0}={1}".format(k, v)
                for k, v in kwargs.items()])
        return url

    @classmethod
    def _get(cls, ra, dec, radius, outtype=1):
        cachekey = (ra, dec, radius)
        if cachekey in cls.__cache:
            return cls.__cache[cachekey]
        url = cls._build_url(ra=ra, dec=dec, radius=radius, outtype=outtype)
        r = requests.get(url, headers={'User-Agent' : cls.agent})
        cls.__cache[cachekey] = r
        return r

    @classmethod
    def query(cls, ra, dec, radius, outtype='1'):
        ra = float(ra)
        dec = float(dec)
        radius = float(radius)
        outtype = int(outtype)
        r = cls._get(ra, dec, radius, outtype)
        return pd.read_csv(StringIO(r.text))