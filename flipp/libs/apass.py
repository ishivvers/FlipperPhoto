# -*- coding:utf-8 -*-

from __future__ import unicode_literals
from builtins import str

import requests
from astropy.table import Table

from StringIO import StringIO

class Client(object):
    """FLIPP Python client for accessing and querying the APASS database.

    Example
    -------

    .. code-block::

        from flipp.libs.apass import Client as APASS

        print(APASS.query(5, 5, 1.))
    """

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
        """Queries the APASS database.

        Notes
        -----
        Original download and AAVSO documentation can be found at
        https://www.aavso.org/download-apass-data

        Parameters
        ----------
        ra : str, float, int
            Right Ascension in sexagesmial (HH:MM:SS, DD:MM:SS) or
            decimal degrees (##.#)
        dec : float
            Declination in sexagesmial (HH:MM:SS, DD:MM:SS) or
            decimal degrees (##.#)
        radius : float
            Radius to search around in decimal degrees (#.#)
        outtype : int, optional (Default : 1)
            This determines the datatype of the actual request to AAVSO
            Currently, only handling for csv is available, so changing this
            will break -- 0 for HTML, 1 for CSV

        Returns
        -------
        astropy.table.Table
            astropy Table of APASS search results.
        """
        r = cls._get(ra, dec, radius, outtype)
        assert r.status_code == 200, "Invalid query"
        # replace all values labeled 'NA' with NaN, so numpy can handle it
        text = r.text.replace('NA','NaN')
        return Table.read(StringIO(text), format="ascii.csv")
