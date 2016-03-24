import numpy as np
from astropy.io import fits
import os
from datetime import datetime
from flipp.libs import astrometryWrap,fileio

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
    
    def getAstrometry(self):
        if self.telescope == 'kait':
            self.workingImage = astrometryWrap.astrometry_kait( self.workingImage, self.tempfolder )
        elif self.telescope == 'nick':
            self.workingImage = astrometryWrap.astrometry_nickel( self.workingImage, self.tempfolder )

    def moveFile(self):
        """Move a verified file to permanent location.

        For now this simply uses /media/LocalStorage/ as a testbed.
        """
        header = fileio.get_head( self.workingImage )
        # pull info from the headers, formatted differently for kait and nickel
        if self.telescope == 'kait':
            obsdate = datetime.strptime( header['date-obs']+' '+header['ut'], '%d/%m/%Y %H:%M:%S' )
            telcode = 'k'
            filt = header['filters'].strip()
        elif self.telescope == 'nick':
            obsdate = datetime.strptime( header['date-obs']+' '+header['utmiddle'].split('.')[0], '%d/%m/%y %H:%M:%S' )
            telcode = 'n'
            filt = header['filtnam'].strip()
        # format the date+time string we want
        obsdate_s = obsdate.strftime( '%Y%m%d' )
        fractional_day = obsdate.hour / 24.0
        fractional_day += obsdate.minute / (60.0*24.0)
        fractional_day += obsdate.second / (60.0*60.0*24.0)
        obsdate_ymd = obsdate_s
        obsdate_s += ("%.4f"%fractional_day).lstrip('0')
        # pull info from headers that are consistent across the two telescopes
        targetName = header['object'].replace(' ','').replace('_','-').lower()
        # format final filename 
        filename = "%s_%s_%s_%s_cal.fit" %(targetName, obsdate_s, telcode, filt)
        # and move it
        finalfolder = '%s/%s'%(self.donefolder, obsdate_ymd)
        os.system( 'mkdir -p %s'%finalfolder )
        os.system( 'cp %s %s/%s'%(self.workingImage, finalfolder,filename) )
        self.finalImage = '%s/%s'%(finalfolder, filename)
        return
        
    def run(self):
        """Run all validation methods."""
        # move the file to the temp folder
        self.workingImage = "%s/%s" %(self.tempfolder, os.path.basename(self.inputImage))
        os.system( "cp %s %s"%(self.inputImage, self.workingImage) )
        # actually run astrometry and record the output
        self.getAstrometry()
        # if that was successful, rename and move the file to the appropriate location
        self.moveFile()
        

class KaitChecker(baseChecker):
    def __init__(self, inputImage):
        self.telescope = 'kait'
        self.inputImage = inputImage
        self.tempfolder = "/media/LocalStorage/tmp"
        self.donefolder = "/media/LocalStorage/reduced_images/kait" # here as a testbed for now

class NickelChecker(baseChecker):
    def __init__(self, inputImage):
        self.telescope = 'nick'
        self.inputImage = inputImage
        self.tempfolder = "/media/LocalStorage/tmp"
        self.donefolder = "/media/LocalStorage/reduced_images/nickel" # here as a testbed for now
