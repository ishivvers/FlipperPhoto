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
        self.test_img = image_factory(1024)

        self.S = SE.Sextractor()
        self.extract = self.S.extract

    def test_extract(self):
        """Test various edge cases and use cases of SExtractor."""

        gkait = self.extract(self.good_kait)
        self.assertEquals(len(gkait), 8) # Test real image
        test_img = self.extract(self.test_img)
        self.assertEquals(len(test_img), 1) # Test dummy

