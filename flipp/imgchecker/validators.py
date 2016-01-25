import numpy as np
from astropy.io import fits

class baseChecker(object):
    """Contains methods for good/bad image validation."""

    def is_processed(self):
        """Check if image has been bias and flat field subtracted.

        Returns
        -------
        bool,
            ``True`` if yes, ``False`` if no
        """
        raise NotImplementedError

    def binImage(self, data, n, margin = 0):
        """Bin 2-D img data into n x n grid of sub-images.
        
        Parameters
        ----------
        data : np.array
            2-D array of image data
        n : int
            dimensions of grid of subimages
        margin : int, optional
            margin from the sides to consider
        
        Returns
        ------- 
        bins : list,
            list of near-or-perfect-square 2-D np.arrays

        Example
        -------

        .. code-block:: python

            import numpy as np
            from flipp.validators import baseChecker
            checker = baseChecker()
            data = np.arange(36).reshape(6, 6)
            checker.binImage(data, n = 2, margin = 1)

        """
        if margin > 0:
            data = data[margin:-1*margin, margin:-1*margin]
        # Cut once alongside 0 axis
        longCut = np.array_split(data, n, axis=0)
        bins = []
        for cut in longCut:
            bins.extend(np.array_split(cut, n, axis=1))
        return bins

    def checkBGBrightness(self, data, n=100, margin=30):
        """Compare darkest pixels of n*n sub images.
        
        Parameters
        ----------
        data : np.array
            2-D array of image data
        n : int, optional
            square root of total number of bins to create
            defaults to 100
        margin : int, optional
            margins to apply to binning procedure
            defaults to 30

        Returns
        -------
        bool
            True if image is "good", False otherwise
        """

        # Bin image 
        bins = self.binImage(data, n, margin)
        minAvgs = []
        for b in bins:
            flat = b.flatten()
            flat.sort()
            # Take median of darkest 10% 
            avgDark = np.median(flat[:int(.1*flat.shape[0])])
            minAvgs.append(avgDark)

        minAvgs = np.array(minAvgs)
        st = minAvgs.std()
        # if spread of dark values too big, either too many bins
        # or gradient-like image
        # Count the number of bins 2 std deviations away
        # Mask for dark outliers
        dark = minAvgs[minAvgs < minAvgs.mean() - 2*st]
        # Mask for bright outliers
        bright = minAvgs[minAvgs > minAvgs.mean() + 2*st]

        # DEFINE THRESHOLD HERE, TEMPORARY PLACEHOLDER VALUE
        # Abnormally dark values are much less expected
        # So threshold should be much more aggressive than for brights
        if len(dark) >= .0125*(n**2):
            return False

        # DEFINE THRESHOLD HERE, TEMPORARY PLACEHOLDER VALUE
        if len(bright) >= 0.025*(n**2):
            return False

        return True

    def run(self):
        """Run all validation methods."""
        pass

class KaitChecker(baseChecker):

    pass

class NickelChecker(baseChecker):

    pass
