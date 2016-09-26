# -*- encoding : utf-8 -*-
import os
from unittest import TestCase

from flipp.libs import sextractor as SE
from flipp.conf import settings

from .factories import image_factory

class TestSextractor(TestCase):
    """Test suite for source extractor wrapper."""

    def setUp(self):
        self.good_kait = os.path.join(settings.FIXTURE_DIR, 'kait', 'goodkait.fits')
        self.bad_kait = os.path.join(settings.FIXTURE_DIR, 'kait', 'badkait.fts.Z')
        self.test_gimg = image_factory(1024, 'center') # Dummy good image
        self.test_bimg = image_factory(1024, 'side') # Dummy bad image

        self.S = SE.Sextractor()
        self.extract = self.S.extract

    def test_extract(self):
        """Test various edge cases and use cases of SExtractor."""

        gkait = self.extract(self.good_kait)
        self.assertEquals(len(gkait), 8) # Test good real image

        # PENDING
        # NEED A WAY TO DETECT BAD IMAGE AT SOURCE EXTRACTOR LEVEL
        self.assertTrue(False)

        test_gimg = self.extract(self.test_gimg)
        self.assertEquals(len(test_gimg), 1) # Test good dummy image
        test_bimg = self.extract(self.test_bimg)
        self.assertEquals(len(test_bimg), 0) # Test bad dummy image
