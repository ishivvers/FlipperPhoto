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
    catalog = base + "_sources.txt"
    objfile = base + "_objects.fit"
    bkgfile = base + "_background.fit"
    extractor_args = " -c %s/default.sex"%SEXCONFPATH +\
                     " -PARAMETERS_NAME %s/default.param"%SEXCONFPATH +\
                     " -FILTER_NAME %s/gauss_3.0_5x5.conv"%SEXCONFPATH +\
                     " -CATALOG_NAME %s"%catalog +\
                     " -CHECKIMAGE_TYPE OBJECTS,BACKGROUND -CHECKIMAGE_NAME %s,%s"%(objfile,bkgfile)
    o,e = Popen( "sextractor "+pathname+extractor_args, shell=True, stdout=PIPE, stderr=PIPE ).communicate()
    return o
