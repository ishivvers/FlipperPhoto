import numpy as np
from unittest import TestCase

from flipp.imgchecker import validators

class TestBaseChecker(TestCase):

    def test_binImage(self):
        """Integration testing for binImage method used to grid subimages."""
        img = np.arange(1024**2).reshape(1024, 1024)
        checker = validators.baseChecker()
        bins = checker.binImage(img, 100, 0)
        # There should be n**2 bins
        self.assertEqual(100**2, len(bins))
        # Top left corner of the first bin is 0 by construction
        self.assertEqual(bins[0][0][0], 0)
        # Bottom right corner of the last bin is 1024**2 - 1 by construction
        self.assertEqual(bins[-1][-1][-1], 1024**2 - 1)

        # Check that margin option works
        margin_bins = checker.binImage(img, 100, 100)
        # Shape of some element with the margined bins must be
        # smaller than that of ``bins`` which was created without margins
        product = lambda x, y : x*y
        # with margins of 100, any element will work by construction
        self.assertTrue(product(*bins[50].shape) > product(*margin_bins[50].shape))

    def test_checkBGBrightness(self):
        """Integration testing for checkBGBrightness method."""
        badImg = np.arange(1024**2).reshape(1024, 1024)
        checker = validators.baseChecker()

        self.assertFalse(checker.checkBGBrightness(badImg))
        