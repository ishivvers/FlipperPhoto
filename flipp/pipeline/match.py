# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os

from flipp.database import engine, models
from flipp.libs import coord

from sqlalchemy.orm import sessionmaker
from sqlalchemy import func, text

Session = sessionmaker(bind=engine)


class SourceMatcher(object):

    def __init__(self, imgparser):
        self.img = imgparser
        self.sources = imgparser.sources
        self.telescope = imgparser.telescope
        self.meta = imgparser.META
        self.session = Session()

    def find_or_create_source(self, source, tolerance=0.5):
        ra = source['ALPHA_J2000']
        dec = source['DELTA_J2000']
        dist = func.sqrt(func.pow(models.Source.ra - ra, 2) +
                         func.pow(models.Source.dec - dec, 2))
        objects = self.session.query(
            models.Source).filter(dist < 3).order_by(dist)
        obj = None
        created = False
        if not objects.count() == 0:
            o = objects.first()
            if coord.ang_sep(ra, dec, o.ra, o.dec) / 2.7784E-4 <= tolerance:
                obj = o
        if not obj:
            obj = self.create_object(source)
            created = True
        return obj, created

    def create_object(self, source, name="", classification=""):
        ra = source['ALPHA_J2000']
        dec = source['DELTA_J2000']
        s = models.Source(
            ra=ra, dec=dec, name=name, classification=classification)
        self.session.add(s)
        self.session.commit()
        return s

    def get_or_create_image(self):
        # self.session.query(models.Image).filter(name=)
        created = False
        q = {'name': os.path.relpath(self.img.output_file, self.img.output_root),
             'telescope': self.telescope,
             'passband': self.meta['FILTER'],
             }

        img = self.session.query(models.Image).filter_by(**q).first()
        if not img:
            q.update(mjd = round(self.meta['MJD'], 5))
            img = models.Image(**q)
            self.session.add(img)
            self.session.commit()
            created = True
        return created, img

    def add_observation(self, source, obj):
        created, img = self.get_or_create_image()
        obs = models.Observation(source=obj.pk,
                                 image=img.pk,
                                 magnitude=source['MAG_AUTO_ZP'],
                                 error=source['MAGERR_AUTO_ZP'],
                                 )

        self.session.add(obs)
        self.session.commit()

    def run(self):
        n_updated = 0
        n_created = 0
        for source in self.sources:
            obj, created = self.find_or_create_source(source)
            if created:
                n_created += 1
            else:
                n_updated += 1
            self.add_observation(source, obj)
        return n_updated, n_created
