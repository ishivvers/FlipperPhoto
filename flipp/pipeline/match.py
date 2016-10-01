# -*- coding: utf-8 -*-

from __future__ import unicode_literals
import pandas as pd

from flipp.database import engine, models
from flipp.libs import coord

from sqlalchemy.orm import sessionmaker
from sqlalchemy import func, text

Session = sessionmaker(bind=engine)

class SourceMatcher(object):

    def __init__(self, cataloged_sources, meta):
        self.sources = cataloged_sources
        self.meta = meta
        self.session = Session()

    def find_or_create_object(self, source, tolerance = 0.5):
        ra = source['ALPHA_J2000']
        dec = source['DELTA_J2000']
        dist = "POW(ra - :ra, 2) + POW(dec - :dec, 2)"
        sql = text("{} < 10.0".format(dist)).params(ra=ra, dec=dec)
        objects = self.session.query(models.Source).filter(sql).order_by(
            text(dist).params(ra=ra,dec=dec))
        obj = None
        created = False
        if not objects.count() == 0:
            o = objects.first()
            if (coord.ang_sep(ra, dec, o.ra, o.dec) / 2.7784E-4) <= tolerance:
                obj = o
        if not obj:
            obj = self.create_object(source)
            created = True
        return obj, created

    def create_object(self, source, name="", classification=""):
        ra = source['ALPHA_J2000']
        dec = source['DELTA_J2000']
        s = models.Source(
            ra=ra, dec=dec, name = name, classification=classification)
        self.session.add(s)
        self.session.commit()
        return s

    def add_observation(self, source, obj):
        obs = models.Observation(source = obj.pk,
            telescope = self.meta['INSTRUMENT'],
            modified_julian_date = self.meta['MJD'],
            magnitude = source['MAG_AUTO_ZP'],
            error = source['MAGERR_AUTO_ZP'],
            filter = self.meta["FILTER"],
            )

        self.session.add(obs)
        self.session.commit()

    def run(self):
        n_updated = 0
        n_created = 0
        for source in self.sources:
            obj, created = self.find_or_create_object(source)
            if created:
                n_created += 1
            else:
                n_updated += 1
            self.add_observation(source, obj)
        return n_updated, n_created
