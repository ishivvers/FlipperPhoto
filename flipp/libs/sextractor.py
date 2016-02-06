"""Wrapper around source extractor, as currently installed
on heracles.

-Isaac, Feb. 5
"""
from subprocess import Popen, PIPE
import fileio
import os

SEXCONFPATH = '/usr/share/sextractor'
def simple_extract( pathname ):
    base,ext = os.path.splitext( pathname )
    objfile = base + "_sobj.fit"
    skyfile = base + "_sky.fit"
    extractor_args = " -c %s/default.sex"%SEXCONFPATH +\
                     " -PARAMETERS_NAME %s/default.param"%SEXCONFPATH +\
                     " -FILTER_NAME %s/gauss_3.0_5x5.conv"%SEXCONFPATH +\
                     " -CATALOG_NAME %s"%objfile +\
                     " -CHECKIMAGE_NAME %s"%skyfile
    o,e = Popen( "sextractor "+pathname+extractor_args, shell=True, stdout=PIPE, stderr=PIPE ).communicate()
    return o