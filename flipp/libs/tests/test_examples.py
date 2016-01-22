"""Example test suite for single module.

Note
----
None of these tests actually test for anything important.
If any of them are failing for whatever reason, just delete them.

- Thomas T,, Jan 21 2016
"""
import os
import matplotlib

# Call this before any import of examples or code containing
# a pyplot import to avoid displaying images in tests
matplotlib.use('Template')

from unittest import TestCase
from astropy.io import fits as pf

from conf import FIXTURE_DIR
from flipp.libs import examples



class Test_plot_one_image(TestCase):
    """Example TestCase, with ideas of what to test.

    Note
    ----
    The setUp and tearDown methods are special methods that are 
    run before and after every test.  
    """

    def setUp(self):
        self.testImgPath = os.path.join(FIXTURE_DIR, 
            'nickel', 'tfn150609.d206.sn2014c.V.fit')

    def test_fixturePath(self):
        """Expected fixture should exist."""
        # Test that path exists
        self.assertTrue(os.path.exists(self.testImgPath))
        # Test that it's actually a fits file
        hduList = pf.open(self.testImgPath)
        self.assertEqual(1, len(hduList))
        self.assertIsInstance(hduList, pf.hdu.hdulist.HDUList)
        hdu = hduList[0]
        self.assertIsInstance(hdu, pf.hdu.image.PrimaryHDU)

        # Example attribute to delete in tearDown
        self.toDelete = 1

    def test_plotOneImg(self):
        """Feeds in expected input, asserts expected output.

        Note
        ----
        This is also called Integration testing, where you aren't
        testing for anything specific, just that the whole package
        works.  Most tests will probably take this form.  
        """

        # Should return nothing since plt.show() is a side effect
        self.assertIsNone(examples.plot_one_image(self.testImgPath))
        # Should not crash if there is no argument since it has a default
        self.assertIsNone(examples.plot_one_image())

    def tearDown(self):
        """Example tearDown.  Useful if testing code with side-effects."""
        if hasattr(self, 'toDelete'):
            delattr(self, 'toDelete')