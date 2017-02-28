# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os
import gc
import re
import argparse

from flipp.pipeline.image import ImageParser
from flipp.pipeline.match import SourceMatcher

from flipp.conf import settings


def process_image(input_file, path_to_output, telescope):
    try:
        img = ImageParser(input_file, path_to_output, telescope)
        sources = img.run()
        if not sources:
            return
        matcher = SourceMatcher(img)
        n_created, n_updated = matcher.run()
        return n_created, n_updated
    except Exception as e:
        msg = "{} Failed with error: {}".format(input_file, e)
        print(msg)
    finally:
        gc.collect()


def run(input_paths, path_to_output=None, telescope=None, extensions=[], recursive=False):
    """Business logic for running task.

    Example
    -------
    .. code-block::
        run("flipp/fixtures/kait/goodkait.fits",
            "/home/ttu/Desktop/goodkait", telescope="kait")
    """
    path_to_output = os.path.abspath(path_to_output)
    R = re.compile('|'.join(map(re.escape, extensions)) + '$', flags=re.I)
    for input_path in input_paths:

        input_path = os.path.abspath(input_path)
        if os.path.isfile(input_path):

            if not R.search(input_path):
                continue
            process_image(input_path, path_to_output, telescope)
        else:  # os.path.isdir(input_path)
            if not recursive:
                for p in filter(os.path.isfile, os.listdir(input_path)):
                    if not R.search(input_path):
                        continue
                    process_image(p, path_to_output, telescope)
            else:  # recursive == True
                for (name, dirs, files) in os.walk(input_path):
                    for f in files:
                        if not R.search(f):
                            continue
                        f = os.path.join(name, f)
                        process_image(f, path_to_output, telescope)

def console_run():
    """Console script entry-point for flipp pipeline."""
    parser = argparse.ArgumentParser(
        description='Run flipp pipeline on a file with some output directory.')

    parser.add_argument("input_files", metavar= "file1 file2 ...", type=str,
        help="filepath to image.", nargs='+')
    parser.add_argument("-o", "--output_dir", metavar="/path/to/output/directory", type=str,
        help = "Directory in which to save outputs", default="outputs")
    parser.add_argument("-t", "--telescope", metavar = "kait/nickel/etc",
        choices = settings.TELESCOPES.keys(),
        help = 'Optional telescope name from allowed names, {}'.format(
            ', '.join(settings.TELESCOPES)),
        default = None,
        )
    parser.add_argument("-r", "--recursive", action="store_true")
    parser.add_argument("-e", "--extensions", type=str, help="valid extensions", nargs = "*",
                        default=["fits", "fts", "fit", "fits.Z", "fts.Z", "fit.Z"])

    args = parser.parse_args()
    run(args.input_files, args.output_dir, args.telescope, args.extensions, args.recursive)
