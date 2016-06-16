import os
import logging

from flipp.libs import fileio,astrometry,sextractor,zeropoint
from datetime import datetime

class image(object):
    """A class that handles an image being processed all the way
    through the pipeline."""
    
    def __init__(self, fname, tel, logfile=None):
        self.fname = fname
        self.logfile = logfile
        
        if tel == 'kait':
            # could replace this by pulling info from header
            self.tel = 'kait'
            self.tempfolder = "/media/LocalStorage/tmp"
            self.donefolder = "/media/LocalStorage/reduced_images/kait" # here as a testbed for now
        else:
            raise Exception('Not yet implemented.')
        
        self.steps = [self.solve_astrometry,
                      self.save_to_file,
                      self.extract_sources,
                      self.apply_zeropoint,
                      self.ingest_to_database]
        self.current_step = 0
        self.build_log()
        
    
    def next(self, *args, **kwargs):
        if self.current_step < len(self.steps):
            self.steps[ self.current_step ]( *args, **kwargs )
            self.current_step += 1
        else:
            raise StopIteration
    
    def run(self):
        while True:
            try:
                self.next()
            except StopIteration:
                self.log.info('FlipperPhot pipeline ended.')
                return
    
    def build_log(self):
        """
        Required to start the log.
        """
        self.log = logging.getLogger('FlipperPhot')
        self.log.setLevel(logging.INFO)
        if self.logfile != None:      
            fh = logging.FileHandler( self.logfile )
            fh.setFormatter( logging.Formatter('%(asctime)s ::: %(message)s') )
            self.log.addHandler(fh)
        # have log messages go to screen
        sh = logging.StreamHandler()
        sh.setFormatter( logging.Formatter('*'*40+'\n%(levelname)s - %(message)s\n'+'*'*40) )
        self.log.addHandler(sh)
        self.log.info('FlipperPhot pipeline started.')
    
    #############################################################################################
    
    def perform_astrometry(self, pretest='sextractor'):
        """Perform astrometry on an image.
        """
        if pretest == 'sextractor':
            threshold = 3
            # use source extractor to vet images before attempting
            #  astrometry, since astrometry takes a lot of time when it fails
            ### THIS DOESN'T WORK VERY WELL :/
            ###  WE SHOULD DO BETTER.
            s = sextractor.Sextractor()
            sources = s.extract( self.fname )
            if len(sources) < threshold:
                raise Exception('Image does not pass sextractor pretest.')
        
        self.workingImage = astrometry.Astrometry(self.fname, self.tel)
        return
    
    def extract_sources(self):
        """Extract sources from image.
        """
        s = sextractor.Sextractor()
        self.sources = s.extract( self.workingImage )
        return
    
    def apply_zeropoint(self):
        """Calculate and apply a zeropoint correction to sextractor catalog.
        """
        self.sources = zeropoint.Zeropoint_apass( self.sources, self.filter )
    
    def save_to_file(self):
        """Save a verified file to its permanent location.
        """
        header = self.workingImage[0].header
        # pull info from the headers, formatted differently for kait and nickel
        if self.tel == 'kait':
            obsdate = datetime.strptime( header['date-obs']+' '+header['ut'], '%d/%m/%Y %H:%M:%S' )
            telcode = 'k'
            filt = header['filters'].strip()
        elif self.tel == 'nick':
            obsdate = datetime.strptime( header['date-obs']+' '+header['utmiddle'].split('.')[0], '%d/%m/%y %H:%M:%S' )
            telcode = 'n'
            filt = header['filtnam'].strip()
        self.filter = filt
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
        finalname = '%s/%s'%(finalfolder, filename)
        os.system( 'mkdir -p %s'%finalfolder ) # if folder does not yet exist, create it
        self.hdu.writeto( finalname )
        self.savedfile = finalname
        return

    def ingest_to_database(self, pos_tolerance=0.5):
        """This is where we will stick data into the database.
        
        pos_tolerance: positional tolerance for cross-matching sources
        """
        pass
        
    