# -*- coding:utf-8 -*-

from __future__ import unicode_literals
from builtins import str

from sqlalchemy.ext.declarative import declarative_base, declared_attr
from sqlalchemy import Column, Integer, String, Float, ForeignKey

Base = declarative_base()

class FlippModel(object):

    @declared_attr
    def __tablename__(cls):
        return "flipp_{}".format(cls.__name__.lower())

    def __unicode__(self):
        return "{}".format(self.__class__.__name__)

    def __str__(self):
        return self.__unicode__()

    def __repr__(self):
        return "<{} : {}>".format(str(self), self.pk)

    pk = Column(Integer, primary_key=True, autoincrement=True)

class Source(FlippModel, Base):

    name = Column(String(length = 255, convert_unicode=True))
    ra = Column(Float)
    dec = Column(Float)

class Observation(FlippModel, Base):

    source = Column(Integer,
        ForeignKey("{}.pk".format(Source.__tablename__)), nullable=False)
    telescope = Column(String(length = 255, convert_unicode=True))
    mjd = Column(Float)
    magnitude = Column(Float)
    error = Column(Float)
    passband = Column(String(length = 100, convert_unicode=True))
    image_name = Column(String(length=999), convert_unicode=True)) # e.g. 201501100/name_of_image.fits
