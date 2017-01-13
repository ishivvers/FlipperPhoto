# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import re
import argparse

from glob import glob

from flipp.pipeline.image import ImageParser
from flipp.pipeline.match import SourceMatcher

from flipp.conf import settings

def run(input_files, path_to_output=None, telescope=None, extensions=[]):
    """Business logic for running task.

    Example
    -------
    .. code-block::
        run("flipp/fixtures/kait/goodkait.fits",
            "/home/ttu/Desktop/goodkait", telescope="kait")
    """
    R = '|'.join(map(re.escape, extensions)) + '$'
    for input_file in input_files:
        try:
            if not re.search(R, input_file, flags=re.I):
                continue
            img = ImageParser(input_file, path_to_output, telescope)
            sources = img.run()
            if not sources:
                continue
            matcher = SourceMatcher(img)
            n_created, n_updated = matcher.run()
        except Exception as e:
            msg = "{} Failed with error: {}".format(input_file, e)
            print(msg)

def console_run():
    """Console script entry-point for flipp pipeline."""
    parser = argparse.ArgumentParser(
        description='Run flipp pipeline on a file with some output directory.')

    parser.add_argument("input_files", metavar= "input_files", type=str,
        help="filepath to image.", nargs='+')
    parser.add_argument("-o", "--output_dir", metavar="output_dir", type=str,
        help = "Directory in which to save outputs")
    parser.add_argument("-t", "--telescope", metavar = "telescope",
        choices = settings.TELESCOPES.keys(),
        help = 'Telescope name from allowed names, {}'.format(
            ', '.join(settings.TELESCOPES)),
        default='kait'
        )
    parser.add_argument("-e", "--extensions", type=str, help="valid extensions", nargs = "*",
                        default=["fits", "fts", "fit", "fits.Z", "fts.Z", "fit.Z"])

    args = parser.parse_args()
    run(args.input_files, args.output_dir, args.telescope, args.extensions)
