# -*- coding:utf-8 -*-

from __future__ import unicode_literals
from builtins import str

from sqlalchemy import create_engine

from flipp.conf import settings
from .models import Base

engine = create_engine(settings.DB_URL)
Base.metadata.create_all(engine)
