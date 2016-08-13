import os
import logging

from flipp.libs import fileio,astrometry,sextractor,zeropoint,coord,julian_dates

import MySQLdb
import MySQLdb.cursors
import credentials as creds # not included in git repo

from datetime import datetime


def print_sql( sql, vals=None ):
    """
    Prints an approximation of the sql string with vals inserted. Approximates cursor.execute( sql, vals ).
    Note that internal quotes on strings will not be correct and these commands probably cannot actually be
    run on MySQL - for debugging only!
    """
    print '\nSQL command:\n'
    if vals == None:
        print sql
    else:
        s = sql %tuple( map(str, vals) )
        print s

class image(object):
    """A class that handles an image being processed all the way
    through the pipeline.
    """
    
    def __init__(self, fname, tel, logfile=None):
        self.fname = fname
        self.logfile = logfile
        
        # connect to the DB
        self.DB = MySQLdb.connect(host=creds.host, user=creds.user, passwd=creds.passwd, \
                                  db=creds.db, cursorclass=MySQLdb.cursors.DictCursor)
        
        # find which telescope and filter this image is; maybe in a subfunction
        #  called pull_header_info
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
    
    def pull_header_info(self):
        """Pull relevant info from header file before going through the pipeline.
        """
        self.header = fileio.get_head( self.fname )
        inst = self.header.get('INSTRUME').strip()
        if inst == 'K.A.I.T':
            self.tel = 'kait'
        elif 'Nickel' in inst:
            self.tel = 'nick'
        # other tests?
        if self.tel == 'nick':
            self.filter = header['filtnam'].strip()
            self.obsdate = datetime.strptime( header['date-obs']+' '+header['utmiddle'].split('.')[0], '%d/%m/%y %H:%M:%S' )
        elif self.tel == 'kait':
            self.filter = header['filters'].strip()
            self.obsdate = datetime.strptime( header['date-obs']+' '+header['ut'], '%d/%m/%Y %H:%M:%S' )
        # calculate modified Julian date
        jd = julian_dates.julian_date(self.obsdate.year, self.obsdate.month, self.obsdate.day, 
                                      self.obsdate.hour, self.obsdate.minute, self.obsdate.second )
        self.mjd = julian_dates.jd2mjd( jd )
        
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
        return

    def ingest_to_database(self):
        """This is where we will stick data into the database.
        
        pos_tolerance: positional tolerance for cross-matching sources
        """
        for source in self.sources:
            db_object_id = _query_DB_object( source['ALPHA_J2000'], source['DELTA_J2000'] )
            if db_object_id == None:
                # if an object at this coordinate doesn't exist yet, create one!
                _create_new_DB_object( source )
                db_object_id = _query_DB_object( source['ALPHA_J2000'], source['DELTA_J2000'] )
            # now that an object exists at this location, add this observation!
            _add_observation( source, db_object_id )
        return
            
    def _query_DB_object( self, ra, decl, pos_tolerance=0.5 ):
        """
        Queries DB for all objects within pos_tolerance arcseconds 
         of given coordinates in attempt to match to the coordinates.
        
        ra, decl: must be in decimal degrees
        pos_tolerance: the positional cross-match tolerance for sources to be marked
         the same; in arcseconds
        """
        # perform a first-pass query, pulling sources from a subset of the sky to compare against
        sqlfind = 'SELECT id, (POW(ra - %s, 2) + POW(decl - %s, 2)) AS dist FROM objects '+\
                  'HAVING dist < 10.0 ORDER BY dist LIMIT 10;' 
        c = self.DB.cursor()
        c.execute( sqlfind, vals )
        r = c.fetchall( )
        # calculate the true on-sky angular seperation of the nearest result
        dist = coord.ang_sep(ra,decl, r[0]['ra'],r[0]['decl']) * 2.778e-4 # in arcseconds
        
        if dist <= pos_tolerance:
            # found a match!
            return r[0]['id']
        else:
            # did not find a match
            return None
        
    def _create_new_DB_object( self, source, objname='', objtype='' ):
        """
        Create a new object in the database, given a source (i.e. a row of self.sources)
        """
        sqlinsert = "INSERT INTO objects (ra, decl, name, type) "+\
                                 "VALUES (%s, %s, %s, %s);"
        vals = [source['ALPHA_J2000'], source['DELTA_J2000'], objname, objtype]

        # now go ahead and put it in
        print_sql( sqlinsert, vals )
        c = self.DB.cursor()
        c.execute( sqlinsert, vals )
        self.DB.commit()
        return 
    
    def _add_observation( self, source, db_object_id):
        """
        Add an observation to the database, crosslinked to a specific source on the sky.
        
        For now, this assumes all data is through the KAIT clearband, so it just
         all goes into the kait_clear table.
        """
        sqlinsert = "INSERT INTO kait_clear (obj_id, mjd, mag, err) "+\
                                 "VALUES (%s, %s, %s, %s);"
        vals = [db_object_id, self.mjd, source['MAG_AUTO_ZP'], source['MAGERR_AUTO_ZP']]

        # now go ahead and put it in
        print_sql( sqlinsert, vals )
        c = self.DB.cursor()
        c.execute( sqlinsert, vals )
        self.DB.commit()
        return
        