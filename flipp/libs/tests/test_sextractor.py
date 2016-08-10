# -*- encoding : utf-8 -*-
import os
from unittest import TestCase

from flipp.libs import sextractor as SE
from conf import FIXTURE_DIR

from .factories import image_factory

class TestSextractor(TestCase):
    """Test suite for source extractor wrapper."""

    def setUp(self):
        self.good_kait = os.path.join(FIXTURE_DIR, 'kait', 'goodkait.fits')
        self.bad_kait = os.path.join(FIXTURE_DIR, 'kait', 'badkait.fts.Z')

    def test_extract(self):
        self.assertTrue(True)
        s = SE.Sextractor()
        sources = s.extract(self.good_kait)
        self.assertEquals(len(sources), 8) # Test real image

        self.assertEquals(len(s.extract(image_factory(1000))), 1) # Test dummy
