import os
import logging

PROJECT_DIR = os.path.abspath(os.path.dirname(__file__))
FIXTURE_DIR = os.path.join(PROJECT_DIR, "flipp", "fixtures")

SEXCONFPATH = os.path.join(PROJECT_DIR, "flipp", "libs", "sextractor_config")
ASTROMETRYCONF = "/usr/local/astrometry/etc/astrometry.cfg"
#ASTROMETRYCONFPATH = os.path.join(PROJECT_DIR, "flipp", "libs", "astrometry")


TELESCOPES = {
    "kait" : {
        "pixscaleL" : 0.79,
        "pixscaleH" : 0.80
        },
    "nickel" : {
        "pixscaleL" : 0.36,
        "pixscaleH" : 0.38,
        },
}

