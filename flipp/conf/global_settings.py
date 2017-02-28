# -*- coding: utf-8 -*-
import os

# ==============================================
# INTERNAL SETTINGS : AVOID CHANGING IF POSSIBLE
# ==============================================
# USED INTERNALLY TO REFERENCE KNOWN FILES RELATIVE TO THE "flipp" FOLDER
# FOR THINGS THAT REQUIRE ABSOLUTE PATHS.
PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
FIXTURE_DIR = os.path.join(PROJECT_DIR, "fixtures")


# =======================================
# GLOBAL SOURCE-EXTRACTOR CONFIG SETTINGS
# =======================================

# USED INTERNALLY TO SET DEFAULTS FOR TELESCOPE-SPECIFIC SETTINGS
# SEE THE TELESCOPES SETTING FOR AN EXAMPLE.  IF YOU OVERRIDE THIS,
# IT WILL PROBABLY BE BECAUSE YOU ARE CREATING A NEW/UPDATED SET OF DEFAULTS.
# OVERRIDING THIS LOCALLY WILL HAVE NO IMPACT.
SEXCONFPATH = os.path.join(PROJECT_DIR, "libs", "sextractor_config")

# PATH TO SOURCE-EXTRACTOR BINARY
SEXTRACTORPATH = "/usr/bin/sextractor"


# =================================
# GLOBAL ASTROMETRY CONFIG SETTINGS
# =================================

# USED INTERNALLY TO SET DEFAULTS FOR TELESCOPE-SPECIFIC SETTINGS
# SEE THE TELESCOPES SETTING FOR AN EXAMPLE.  IF YOU OVERRIDE THIS,
# IT WILL PROBABLY BE BECAUSE YOU ARE CREATING A NEW/UPDATED SET OF DEFAULTS.
# OVERRIDING THIS LOCALLY WILL HAVE NO IMPACT.
ASTROMETRYCONF = os.path.join(PROJECT_DIR, "libs", "astrometry.cfg")

# PATH TO ASTROMETRY.NET'S solve-field BINARY
SOLVEFIELDPATH = "/usr/bin/solve-field"

# ===========================
# OUTPUT/APP RELATED SETTINGS
# ===========================
# THE flipp APPLICATION HAS TWO MAIN OUTPUTS :
# 1.  A WCS-CORRECTED IMAGE
# 2.  RELEVANT SOURCE INFORMATION DUMPED TO A SINGLE DATABASE

# DEFAULT OUTPUT DIRECTORY FOR flipprun WCS-CORRECTED IMAGES
OUTPUT_ROOT = os.path.abspath(os.path.join(os.path.expanduser('~'),
                                           "FLIPPOUT"))

# DATABASE URI TO RECORD BRIGHTNESS/SOURCE INFORMATION
# SEE http://docs.sqlalchemy.org/en/latest/core/engines.html FOR OPTIONS
# TO USE MySQL : "mysql://db_usr:db_psw@db_host/db_name"
DB_URL = "sqlite://"

# FITS-HEADERS TO USE TO ATTEMPT TO FIGURE OUT TELESCOPE NAMES
# IF YOU HAVE FITS HEADERS THAT DESCRIBE THE INSTRUMENT NAME, THEY
# SHOULD GO HERE, OR ELSE YOU'LL HAVE TO EXPLICITLY PASS IN THE
# TELESCOPE NAME EVERYWHERE
INSTRUMENT_HEADERS = ("INSTRUME",
                      "TELESCOP",
                      "TELESCOPE",
                      )


# TELESCOPE/INSTRUMENT SPECIFIC SETTINGS :
# THE ENTIRE flipp APPLICATION ASSUMES CERTAIN PROPERTIES OF AN IMAGE INHERIT
# FROM THE TELESCOPE / INSTRUMENT.  A COMPLETE EXAMPLE IS BELOW.
TELESCOPES = {
    # TOP LEVEL KEYS ARE TELESCOPE NAMES
    # TELESCOPE NAMES ARE USED TO ATTEMPT TO GUESS THE INSTRUMENT OF AN IMAGE.
    "kait": {
        # COMMAND LINE ARGUMENTS TO PASS TO ASTROMETRY.NET'S solve-field
        # BOOLEAN ARGS TAKE A "None" VALUE
        "ASTROMETRY_OPTIONS": {
            "L": 0.79,  # --scale-low
            "H": 0.80  # --scale-high
        },
        # COMMAND LINE ARGUMENTS TO PASS TO SOURCE-EXTRACTOR
        # BOOLEAN ARGS TAKE A "None" VALUE
        "SEXTRACTOR_OPTIONS": {
            "c": os.path.join(SEXCONFPATH, 'default.kait.sex'),
            "FILTER_NAME": os.path.join(SEXCONFPATH, 'gauss_3.0_5x5.conv')
        },
        # FLIPP REQUIRES FITS HEADERS TO BE NORMALIZED.  THE HEADER_MAPS
        # SETTING TELLS THE FLIPP APPLICATION WHERE TO FIND REQUIRED CARDS
        # USED FOR ``flipp.pipeline.image.ImageParser``
        # WE REQUIRE THE FOLLOWING HEADERS TO BE DECLARED :
        # "FILTER" : Filter used for the image
        # "DATE" : Date of observation
        # "DATETIME" : Time of observation (in UT)
        # "OBJECT" : Name of object telescope is pointing at
        # "DATID" : semi-required, identifier for image on obs night
        "HEADER_MAPS": {
            "FILTER": "FILTERS",
            "DATE": "date-obs",
            "TIME": "ut",
            "OBJECT": "object",
            "DATID": "datid",
        },
    },
    "nickel": {
        "ASTROMETRY_OPTIONS": {
            "L": 0.36,  # --scale-low
            "H": 0.38  # --scale-high
        },
        "SEXTRACTOR_OPTIONS": {
            "c": os.path.join(SEXCONFPATH, 'default.nickel.sex'),
            "FILTER_NAME": os.path.join(SEXCONFPATH, 'gauss_5.0_9x9.conv')
        },
        "HEADER_MAPS": {
            "FILTER": "FILTNAM",
            "DATE": "DATE-OBS",
            "TIME": "UTMIDDLE",
            "OBJECT": "OBJECT",
            # "DATID" : "OBSNUM"
        },
    },
}


# LOGGING CONFIGURATION : YOU CAN CHANGE THE LOGGING TEMPLATE, LEVEL, ETC HERE
# SEE : https://docs.python.org/2/library/logging.config.html
LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'root': {
        'level': 'WARNING',
        'handlers': ['console'],
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s '
                      '%(name)s %(file)s %(message)s',
            'datefmt': '%Y-%m-%d %H:%M:%S',
        },
        'short': {
            'format': '%(levelname)s %(asctime)s %(module)s %(message)s',
            'datefmt': '%H:%M:%S'
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
            'handlers': ['console', ],
            'level': 'DEBUG',
            'propagate': False,
        },
        'flipp': {
            'handlers': ['log_file'],
            'level': 'DEBUG',
            'propagate': True,

        },
    }
}
