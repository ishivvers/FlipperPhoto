# -*- coding: utf-8 -*-

from __future__ import unicode_literals
import argparse

from flipp.pipeline.image import ImageParser
from flipp.pipeline.match import SourceMatcher

from flipp.conf import settings

def run(path_to_img, path_to_output, telescope):
    """Business logic for running task.

    Example
    -------
    .. code-block::
        run("flipp/fixtures/kait/goodkait.fits",
            "/home/ttu/Desktop/goodkait", telescope="kait")
    """
    img = ImageParser(path_to_img, path_to_output, telescope)
    sources = img.run()
    if not sources: return
    matcher = SourceMatcher(sources, img.META)
    n_created, n_updated = matcher.run()

def console_run():
    """Console script entry-point for flipp pipeline."""
    parser = argparse.ArgumentParser(
        description='Run flipp pipeline on a file with some output directory.')

    parser.add_argument("input_file", metavar= "input_file", type=str,
        help="filepath to image.")
    parser.add_argument("output_dir", metavar="output_dir", type=str,
        help = "Directory in which to save outputs")
    parser.add_argument("telescope", metavar = "telescope",
        choices = settings.TELESCOPES.keys(),
        help = 'Telescope name from allowed names, {}'.format(
            ', '.join(settings.TELESCOPES))
        )

    args = parser.parse_args()
    run(args.input_file, args.output_dir, args.telescope)
