import numpy as np
from astropy.io import fits

class baseChecker(object):

    def is_processed(self):
        """Check if image has been bias and flat field subtracted.

        Returns
        -------
        bool,
            ``True`` if yes, ``False`` if no
        """
        raise NotImplementedError

    def binImage(self, data, n, margin = 0):
        """Bin 2-D image into n x n near square arrays.
        
        Parameters
        ----------
        data : np.array
            2-D array of 
        n : TYPE
            Description
        margin : int, optional
            margin from the sides to consider
        
        Returns
        ------- 
        bins : list,
            list of near-or-perfect-square 2-D np.arrays
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
        """."""

        # Bin image 
        bins = self.binImage(data, n, margin)
        minAvgs = []
        for b in bins:
            flat = b.flatten()
            flat.sort()
            # Take median of darkest 10% 
            avgDark = np.median(flat[:int(.1*flat.shape[0])])
            minAvgs.append(avgMin)

        minAvgs = np.array(minAvgs)
        st = minAvgs.std()
        # Count the number of bins 2 std deviations away
        # Mask for dark outliers
        dark = mask[minAvgs < 2*st]
        # Mask for bright outliers
        bright = mask[minAvgs > 2*st]

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
        self.is_processed()