# -*- coding: utf-8 -*-

import os
import logging

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
FIXTURE_DIR = os.path.join(PROJECT_DIR, "fixtures")

SEXCONFPATH = os.path.join(PROJECT_DIR, "libs", "sextractor_config")
SEXTRACTORPATH = "/usr/bin/sextractor"
ASTROMETRYCONF = os.path.join(PROJECT_DIR, "libs", "astrometry.cfg")
SOLVEFIELDPATH = "/usr/bin/solve-field"
#ASTROMETRYCONFPATH = os.path.Desktopjoin(PROJECT_DIR, "flipp", "libs", "astrometry")

OUTPUT_ROOT = os.path.abspath(os.path.join(os.path.expanduser('~'), "FLIPPOUT"))

INSTRUMENT_HEADERS = ["INSTRUME",
                   "TELESCOP",
                   "TELESCOPE",
                  ]

TELESCOPES = {
    "kait" : {
        "ASTROMETRY_OPTIONS" : {
            "L" : 0.79, # --scale-low
            "H" : 0.80  # --scale-high
            },
        "HEADER_MAPS" : {
            "FILTER" : "FILTERS",
            "DATE" : "date-obs",
            "TIME": "ut",
            "OBJECT" : "object",
            "DATID" : "datid",
            },
        },
    "nickel" : {
        "ASTROMETRY_OPTIONS" : {
            "L" : 0.36, # --scale-low
            "H" : 0.38  # --scale-high
            },
        "HEADER_MAPS" : {
            "FILTER" : "FILTNAM",
            "DATE" : "DATE-OBS",
            "TIME": "UTMIDDLE",
            "OBJECT" : "OBJECT",
            # "DATID" : "OBSNUM"
            },
        },
}

DB_URL = "sqlite://"

LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'root' : {
        'level' : 'WARNING',
        'handlers' : ['console'],
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s '
                      '%(name)s %(file)s %(message)s',
            'datefmt': '%Y-%m-%d %H:%M:%S',
            },
        'short' : {
            'format': '%(levelname)s %(asctime)s %(module)s %(message)s',
            'datefmt' : '%H:%M:%S'
            }
        },

    'handlers': {
        'null': {
            'level': 'ERROR',
            'class': 'logging.NullHandler',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'short'
            },
        'log_file': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(PROJECT_DIR, 'flipp.log'),
            'maxBytes': '16777216',  # 16 megabytes
            'formatter': 'verbose'
        }
        },

    'loggers': {
        '': {
            'handlers': ['console',],
            'level': 'DEBUG',
            'propagate': False,
            },
        'flipp': {
            'handlers' : ['log_file'],
            'level': 'DEBUG',
            'propagate': True,

        },
    }
}
