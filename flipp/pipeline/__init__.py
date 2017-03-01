# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os
import gc
import re
import argparse

from flipp.pipeline.image import ImageParser
from flipp.pipeline.match import SourceMatcher

from flipp.conf import settings


def process_image(input_file, path_to_output,
                  telescope=None,
                  skip_astrometry=False):
    """Processes a single image, goes through the following steps:

    1.  Goes to the ImageParser class
        i.   Validates the image has at least 3 detectable sources
        ii.  Image coordinates are corrected via astrometry.net solve-field
        iii. Sources are extracted via SourceExtractor
        iv.  A zeropoint is done by matching against the APASS catalog
    2.  Remaining sources that have been zeropoint-ed against APASS are cross
        referenced against existing sources in the FLIPP Database
        (flipp/conf/local.py:DB_URL)

    This can be considered the "main" entry-point to using the flipp codebase.
    """
    try:
        img = ImageParser(input_file, path_to_output, telescope)
        sources = img.run(skip_astrometry=skip_astrometry)
        if not sources:
            return
        matcher = SourceMatcher(img)
        n_created, n_updated = matcher.run()
        return n_created, n_updated
    except Exception as e:
        msg = "{} encountered an unhandled exception: {}".format(input_file, e)
        print(msg)
    finally:
        gc.collect()


def run(input_paths, path_to_output=None, telescope=None, extensions=[],
        recursive=False,  skip_astrometry=False):
    """Business logic for running task.

    Example
    -------
    .. code-block::
        run("flipp/fixtures/kait/goodkait.fits",
            "/home/ttu/Desktop/goodkait", telescope="kait")
    """
    path_to_output = os.path.abspath(os.path.expanduser(path_to_output))
    R = re.compile('|'.join(map(re.escape, extensions)) + '$', flags=re.I)
    for input_path in input_paths:
        input_path = os.path.abspath(os.path.expanduser(input_path))
        if os.path.isfile(input_path):
            if not R.search(input_path):
                continue
            process_image(input_path, path_to_output,
                          telescope, skip_astrometry)
        else:  # os.path.isdir(input_path)
            if not recursive:  # Just check directory files
                paths = map(lambda x: os.path.abspath(
                                      os.path.join(input_path, x)),
                            os.listdir(input_path))
                for p in filter(os.path.isfile, paths):
                    if not R.search(p):
                        continue
                    process_image(p, path_to_output,
                                  telescope, skip_astrometry)
            else:  # recursive == True
                for (name, dirs, files) in os.walk(input_path):
                    for f in files:
                        if not R.search(f):
                            continue
                        f = os.path.join(name, f)
                        process_image(f, path_to_output,
                                      telescope, skip_astrometry)


def console_run():
    """Console script entry-point for flipp pipeline."""
    parser = argparse.ArgumentParser(
        description='Run flipp pipeline on a file with some output directory.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("input_files",
                        metavar="file1 file2 ...", type=str, nargs='+',
                        help="filepath or directory containing images.")
    parser.add_argument("-o", "--output_dir",
                        metavar="/path/to/output/directory", type=str,
                        default=settings.OUTPUT_ROOT,
                        help="Directory in which to save outputs", )
    parser.add_argument("-t", "--telescope", metavar="kait/nickel/etc",
                        choices=settings.TELESCOPES.keys(), default=None,
                        help=('Optional telescope name from allowed names: {}.'
                              ' If none, guesses from fits header').format(
                            ', '.join(settings.TELESCOPES))
                        )
    parser.add_argument("-r", "--recursive", action="store_true",
                        help="If set, recurses through all directories within "
                             "any input directories.")
    parser.add_argument("-e", "--extensions", type=str, metavar="ext",
                        help="valid extensions", nargs="*",
                        default=["fits", "fts", "fit",
                                 "fits.Z", "fts.Z", "fit.Z"])
    parser.add_argument("-s", "--skip_astrometry", action="store_true",
                        help="Assume wcs-coordinates are correct.  Warning : "
                             "Difficult to undo, please use with certainty!")

    args = parser.parse_args()

    run(args.input_files, args.output_dir, args.telescope,
        args.extensions, args.recursive, args.skip_astrometry)
