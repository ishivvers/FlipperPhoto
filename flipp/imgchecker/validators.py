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

    def countSourceImgs(self, n=10):
        # Pseudo code
        # num_objects = sextractor(fitsfile).num_objects
        # if num_objects <= n:
        #     return False
        # else:
        #     return True

        raise NotImplementedError

    def run(self):
        """Run all validation methods."""
        pass

class KaitChecker(baseChecker):

    pass

class NickelChecker(baseChecker):

    pass
