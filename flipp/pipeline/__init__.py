# -*- coding: utf-8 -*-

from __future__ import unicode_literals

from flipp.pipeline.image import ImageParser
from flipp.pipeline.match import SourceMatcher


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
    if not sources:
        return
    matcher = SourceMatcher(sources, img.META)
    n_created, n_updated = matcher.run()
