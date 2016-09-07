# -*- coding : utf-8 -*-

from __future__ import unicode_literals
from builtins import str

from sqlalchemy import create_engine

from conf import DB_URL
from .models import Base

engine = create_engine(DB_URL)
Base.metadata.create_all(engine)
