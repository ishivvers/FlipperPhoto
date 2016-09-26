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

    pk = Column(Integer, primary_key=True)

class Object(FlippModel, Base):

    name = Column(String(length = 255, convert_unicode=True))
    type = Column(String(length = 255, convert_unicode=True))
    right_ascension = Column(Float)
    declination = Column(Float)

    @property
    def ra(self):
        return self.right_ascension

    @property
    def dec(self):
        return self.declination

class Telescope(FlippModel, Base):

    name = Column(String(length = 255, convert_unicode=True))

class Observation(FlippModel, Base):

    obj_id = Column(Integer,
        ForeignKey("{}.pk".format(Object.__tablename__)), nullable=False)
    telescope = Column(Integer,
        ForeignKey("{}.pk".format(Telescope.__tablename__)), nullable=False)
    modified_julian_date = Column(Float)
    magnitude = Column(Float)
    error = Column(Float)
    filter = Column(String(length = 100, convert_unicode=True))
