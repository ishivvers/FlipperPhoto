# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os

from flipp.database import engine, models

from astropy.coordinates import SkyCoord
from astropy import units
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

    def find_or_create_source(self, source, tolerance=10.0):
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
            c_source = SkyCoord(ra=[ra*units.degree],dec=[dec*units.degree])
            c_object = SkyCoord(ra=[o.ra*units.degree],dec=[o.dec*units.degree])
            idx, sep2d, dist3d = c_source.match_to_catalog_sky( c_object )
            if sep2d[0] <= tolerance*units.arcsecond:
                obj = o
        if not obj:
            obj = self.create_source(source)
            created = True
        return obj, created

    def create_source(self, source, name="", classification=""):
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
        img_created, img = self.get_or_create_image()
        q = {
            'source' : obj.pk,
            'image' : img.pk,
        }
        if not self.session.query(models.Observation).filter_by(**q).first():
            q.update({
                    'magnitude' : source['MAG_AUTO_ZP'],
                    'error' : source['MAGERR_AUTO_ZP']
                    })
            obs = models.Observation(**q)
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
