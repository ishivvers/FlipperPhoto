import os
import logging

from flipp.libs import fileio,astrometry,sextractor,zeropoint

from datetime import datetime

class image(object):
    """A class that handles an image being processed all the way
    through the pipeline.
    """
    
    def __init__(self, fname, logfile=None):
        self.fname = fname
        self.logfile = logfile

        self.build_log()
        self.pull_header_info()

        self.tempfolder = "/media/LocalStorage/tmp"
        self.donefolder = "/media/LocalStorage/reduced_images/"+self.tel
        
        self.steps = [self.solve_astrometry,
                      self.save_to_file,
                      self.extract_sources,
                      self.apply_zeropoint,
                      self.ingest_to_database]
        self.current_step = 0
        
    
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
                self.cleanup()
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
        return
    
    def cleanup(self):
        for handler in self.log.handlers: #clean up the loggers for the next file
            self.log.removeHandler(handler)

    #############################################################################################

    def pull_header_info(self):
        """Pull relevant info from header file before going through the pipeline.
        """
        self.header = fileio.get_head( self.fname )
        inst = self.header.get('INSTRUME').strip()
        if inst == 'K.A.I.T.':
            self.tel = 'kait'
        elif 'Nickel' in inst:
            self.tel = 'nick'
        # other tests?
        if self.tel == 'nick':
            self.filter = self.header['filtnam'].strip()
            self.obsdate = datetime.strptime( self.header['date-obs']+' '+self.header['utmiddle'].split('.')[0], '%d/%m/%y %H:%M:%S' )
        elif self.tel == 'kait':
            self.filter = self.header['filters'].strip()
            self.obsdate = datetime.strptime( self.header['date-obs']+' '+self.header['ut'], '%d/%m/%Y %H:%M:%S' )
        self.log.info('IMAGE: %s \nTELESCOPE: %s\nFILTER: %s\nDATE/TIME %s'%(self.fname, self.tel, self.filter, self.obsdate.strftime('%Y-%m-%d %H:%M:%S')))
        return
    
    def solve_astrometry(self, pretest='sextractor'):
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
        
        a = astrometry.Astrometry(self.fname, self.tel)
        self.workingImage = a.solve()
        if self.workingImage == None:
            raise Exception('Astrometry failed.')
        self.log.info('astrometry completed successfully')
        return
    
    def extract_sources(self):
        """Extract sources from image.
        """
        s = sextractor.Sextractor()
        self.sources = s.extract( self.workingImage )
        self.log.info('sextractor found and extracted %d sources'%len(self.sources))
        return
    
    def apply_zeropoint(self):
        """Calculate and apply a zeropoint correction to sextractor catalog.
        """
        self.sources,zp,N = zeropoint.Zeropoint_apass( self.sources, self.filter )
        self.log.info('zeropoint: %.4f (%d sources crossmatched)'%(zp,N))
        return
    
    def save_to_file(self):
        """Save a verified file to its permanent location.
        """
        telcode = self.tel[0]
        # format the date+time string we want
        obsdate_s = self.obsdate.strftime( '%Y%m%d' )
        fractional_day = self.obsdate.hour / 24.0
        fractional_day += self.obsdate.minute / (60.0*24.0)
        fractional_day += self.obsdate.second / (60.0*60.0*24.0)
        obsdate_ymd = obsdate_s
        obsdate_s += ("%.4f"%fractional_day).lstrip('0')
        # pull info from headers that are consistent across the two telescopes
        targetName = self.header['object'].replace(' ','').replace('_','-').lower()
        # format final filename
        filename = "%s_%s_%s_%s_cal.fit" %(targetName, obsdate_s, telcode, self.filter)
        # and write out to disk
        finalfolder = '%s/%s'%(self.donefolder, obsdate_ymd)
        finalname = '%s/%s'%(finalfolder, filename)
        os.system( 'mkdir -p %s'%finalfolder ) # if folder does not yet exist, create it
        self.workingImage.writeto( finalname )
        self.savedfile = finalname
        self.log.info('saved to file %s'%finalname)
        return

    def ingest_to_database(self, pos_tolerance=0.5):
        """This is where we will stick data into the database.
        
        pos_tolerance: positional tolerance for cross-matching sources
        """
        pass
        
    
