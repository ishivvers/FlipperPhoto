; *****************************************************************************
; *****************************************************************************
; This file contains most of the programs necessary to run idlpacman on the
; realtime data analysis pipeline.  It takes no arguments, but needs to be able
; to find a "idlpac.conf" file that contains defintions of various directories
; where files can be found (see "retrieve_conf", below).  The other files 
; needed are "rotse_iii_usno_cal.pro", "write_cobj.pro", 
; "rotse_iii_usnoread.pro", "realtime_burst.pro", and "update_stats.pro".
;
; idlpacman interfaces with the perl script sexpacman.pl, which writes the
; names of sobj files to a list file.  idlpacman processes the top file off
; this list, until no more files are in the list.  It creates a cobj file from
; the sobj file, and then, if the images are from a burst alert, creates web
; pages which display the images and various relevant text information.
;
; idlpacman is meant to run in an infinite loop.
; 
; Search for "main program" to find where the program begins.
; 
; Modification history
;     Don Smith   UM   08/07/02 - Deleted all html subroutines
;     Eli Rykoff  UM   08/26/03 - added linkdir option
;     Sarah Yost  UM   050211 adding the best zero-point
;                             file/structure: bestzp.fit in conf.workdir
;
; *****************************************************************************


; *****************************************************************************
; augment_conf, c
; 
; This function adds certain fields to the structure that we'll need later
; *****************************************************************************
PRO augment_conf, c
  c = create_struct(c, 'sobj', 'blank')
  c = create_struct(c, 'cobj', 'blank')
  c = create_struct(c, 'cimg', 'blank')
  c = create_struct(c, 'gif', 'blank')
  c = create_struct(c, 'tla', 'blk')
  c = create_struct(c, 'grbid', 'blank')
  c = create_struct(c, 'nseq', 0)
  c = create_struct(c, 'root', 'blank')
  c = create_struct(c, 'rootnoseq', 'blank')
  c = create_struct(c, 'date', 'blank')
  c = create_struct(c, 'rac', 0.0)
  c = create_struct(c, 'decc', 0.0)
  c = create_struct(c, 'rotv', 3)
  c = create_struct(c, 'imfile', 'blank')
  c = create_struct(c, 'match', 'blank')
  c = create_struct(c, 'matchfup', 'blank')
END

; *****************************************************************************
; fill_struct, c, file, error
;
; This function takes a given cobj file and fills in various fields of the 
; conf structure that will be useful for various programs.
; *****************************************************************************
PRO fill_struct, c, file, error
  error = 0
  path = str_sep(file, '/')
  i = n_elements(path)
  nprts = str_sep(path[i-1], '_')
  c.tla = strmid(nprts[1], 0, 3)
  c.date = nprts[0]
  c.grbid = nprts[1]
  c.root = nprts[0]+'_'+nprts[1]+'_'+nprts[2]
  c.rootnoseq = nprts[0]+'_'+nprts[1]+'_'+strmid(nprts[2],0,2)
  c.nseq = strmid(nprts[2],2,3)*1
  c.gif = c.root+'.gif'
  c.cimg = c.imgdir+'/'+c.root+'_c.fit'
  c.cobj = c.cobjdir+'/'+c.root+'_cobj.fit'
  c.sobj = file

  ;; and the match structure name should be different if it's a fup
  if (strmid(nprts[1],0,3) eq 'fup') then begin
      ;; it is a fup
      burstname = strmid(nprts[1],4,strlen(nprts[1])-1)
  endif else burstname = nprts[1]

  c.match = nprts[1]+'_'+strmid(nprts[2],0,2)+'_match.fit'
  c.matchfup = burstname+'_'+strmid(nprts[2],0,2)+'_match.fit'

  ; check that sobjfile and _c file exist
  test=findfile(c.sobj,count=scount)
  test=findfile(c.cimg,count=ccount)
  if (scount eq 0) then begin
      print,'SOBJ File '+c.sobj+' does not exist.'
      error = 1
  endif else if (ccount eq 0) then begin
      print,'Image File '+c.cimg+' does not exist.'
      error = 1
  endif else begin
      hdr=headfits(c.cimg)
      ofdc = sxpar(hdr,'offstdec')
      mtdc = sxpar(hdr,'mountdec')
      mtra=sxpar(hdr,'mountra')
      ofra = sxpar(hdr,'offstra')
      cfac = cos(mtdc * !DTOR)
      c.decc = mtdc + ofdc
      c.rac = mtra + ofra/cfac
      IF (ofdc GT 1.0 OR ofdc LT -1.0) THEN c.rotv = 1
  endelse
END

; *****************************************************************************
; getsobj, listfile
; 
; this function queries the given listfile.  If there is a lock file, it waits
; for the lock file to go away.  Once the lock file is gone, it reads in the
; contents of the list file (which is assumed to be a single column of
; strings), and then writes back all but the first string to the listfile
; (i.e. deleting the first string from the file).  The value of the first
; string is returned.  If there is nothing in the listfile, the string
; 'nothing' is returned.  A lock file is generated while the listfile is being
; manipulated, and then deleted upon completion.
; *****************************************************************************

FUNCTION getsobj, listfile
  lockfile = listfile+'.lock'
  outfile = 'nothing'
  ; First, see if the lock file is there
  OPENR, lockun, lockfile, /GET_LUN, ERROR=err
  WHILE (err EQ 0) DO BEGIN 
      close, lockun 
      free_lun, lockun
      wait, 5              ; wait 5 seconds before checking again
      OPENR, lockun, lockfile, /GET_LUN, ERROR=err
  ENDWHILE 

  num_elems = 0
  OPENR, unit, listfile, /GET_LUN, error=oerr
  IF (oerr EQ 0) THEN BEGIN 
      close, unit
      free_lun, unit
  ; Check if any files are in the sobj file list
      SPAWN, 'wc '+listfile, wc_string
      num_elems = long(STRMID(wc_string(0),0,8))
  ENDIF 

  IF (num_elems GT 0) THEN BEGIN 
  ; First, see if the lock file is there
      err = 0
      OPENR, lockun, lockfile, /GET_LUN, ERROR=err
      WHILE (err EQ 0) DO BEGIN 
          print, 'Lock file present, waiting.'
          close, lockun 
          free_lun, lockun
                                ; wait 5 seconds before checking again
          wait, 5
          OPENR, lockun, lockfile, /GET_LUN, ERROR=err
      ENDWHILE 
                                ; Open the lock file before processing sobj list
      openw, lockun, lockfile, /GET_LUN, /DELETE
      printf, lockun, 'reading'
      
                                ; Read in contents of sobj list
      sobja = strarr(num_elems)
      OPENR, unit, listfile, /GET_LUN
      READF, unit, sobja
      CLOSE, unit
      FREE_LUN, unit
                                ; Set working sobj file to first element of list
      sobjfile = sobja[0]
                                ; If there are more than one sobj files in list,
                                ; write all the rest back to the sobj list file
      printf, lockun, 'writing'
      openw, unit, listfile, /GET_LUN
      IF (num_elems GT 1) THEN $
        FOR i=1,num_elems-1 DO printf, unit, sobja[i]
                                ; If no other files present, empty sobj list file
      close, unit
      free_lun, unit
                                ; close and delete lock file
      close, lockun
      free_lun, lockun
      outfile = sobja[0]
  ENDIF 
  return, outfile
END

; *****************************************************************************
; retrieve_conf, cfgfile
;
; This programs reads in the conf file and stores the field/data pairs in a
; structure.  
; *****************************************************************************
FUNCTION retrieve_conf, cfgfile, error
  error = 0
  cfgst = create_struct('test', 0)
  
  test=findfile(cfgfile,count=count)
  if (count ne 1) then error = 1 $
  else begin
      readcol,cfgfile,tag,value,format='(a,a)'
      num_lines=n_elements(tag)

      for i=0,num_lines-1 do begin
          cfgst = create_struct(cfgst, tag[i], value[i])
      endfor

      conftags = ['sobjlist','workdir','sobjdir','cobjdir','imgdir','statdir','statroot','thumbfile','bindir','linkdir','quit','domatch']
      if (not tag_exist(cfgst, 'linkdir')) then cfgst = create_struct(cfgst, 'linkdir', 'null')
      if (not tag_exist(cfgst, 'quit')) then cfgst = create_struct(cfgst, 'quit',0)
      if (not tag_exist(cfgst, 'domatch')) then cfgst = create_struct(cfgst, 'domatch',1)
      FOR i=0,n_elements(conftags)-1 DO IF NOT tag_exist(cfgst, conftags[i]) THEN error = 1
;      help,cfgst,/str
  endelse

  return, cfgst
END

; *****************************************************************************
; get_catalog, c
;
; This function takes the information about the image that is stored in the
; augmented configuration structure "c" and extracts the portion of the
; USNO catalog corresponding to the central 1/16th of the FOV, if the image
; is from ROTSE-I, or the whole image, if from ROTSE-II or III.  It returns
; a catalog structure.
; *****************************************************************************
FUNCTION get_catalog, c
  rarange = 1.5

  extract_usno_db, c.rac, c.decc, rarange, cat

;Now fill with information from USNO
  IF (c.rotv GT 1) THEN astr_struct_new,1.85,astr ELSE astr_struct, astr

  astr.crval=[double(c.rac),double(c.decc)]
  rd2xy,cat.ra,cat.dec,astr,xc,yc ; OUTSIDE
  
  b = 1024
; Just keep part of image
  IF (c.rotv EQ 1) THEN b = b/4
  inpic=where(xc gt -b and xc LT b and yc gt -b and yc lt b,n)
  IF n GT 0 THEN cat=cat(inpic)
  
  return, cat
END

; *****************************************************************************
; Begin main program
;
; A config file (called idlpac.conf) is assumed to be in the initial working
; directory.  This file should contain two columns of strings, the first should
; be the field names and the second should be their values.
;
; Then it reads in the first sobj file name in the output file from sexpacman
; and deletes that file name from said file.
;
; *****************************************************************************
PRO idlpacman
  rotse_setup
; Check to make sure that the catalog path has been set
  spawn, 'printenv ZDBASE', test
  IF (strlen(test[0]) LT 10) THEN $
      print, 'Error: environment variable ZDBASE not set.' $
  ELSE BEGIN 
; Delete the following line when the function is ready for real usage
;      cd, '/home/dasmith/idl.lib/idlpacman'
      conf = retrieve_conf('idlpac.conf', cerr)
      do_stamp = 0
      write_pid = 0
      if (tag_exist(conf, 'stampfile')) then begin
          do_stamp = 1
          write_pid = 1
          ;; and stamp that we've started up
          openw,stamplun,conf.stampfile,/get_lun
          free_lun,stamplun
      endif
      IF (cerr GT 0) THEN print, 'Error reading conf file idlpac.conf' $
      ELSE BEGIN 
; this line adds certain fields to the structure that we'll need later
          augment_conf, conf        
          
; set up the zero-pt offset list: get the structure of bests for every
; sky patrol field. It should be in or linked to the workdir

          zpfile = conf.workdir+'/bestzp.fit'

          zpstr = mrdfits(zpfile,1,status=status)
          if (status LT 0) then begin
              print, "NONFATAL ERROR: no zero-point offset bestzp.fit file in the workdir"
              zpstr = create_struct('fieldname', 'no_img', 'best_zp20', -99.99, 'mlim_ofzp20', -99.99, 'best_zp20file', 'no_img', 'best_zp60', -99.99, 'mlim_ofzp60', -99.99, 'best_zp60file', 'no_img')
 
          endif


; Set up an infinite loop
          loop = 1
          WHILE(loop) DO BEGIN 
              cd, conf.workdir
              newfile = getsobj(conf.sobjlist)
              IF (newfile EQ 'nothing') THEN begin
                  if (conf.quit) then loop = 0 else wait, 10
              endif else begin
; First, fill in the conf structure with useful values
                  print,'Beginning sobjfile '+newfile
                  fill_struct, conf, newfile,ferror
; First, create the cobj file from the sobj file, if it does not exist
                  if (ferror eq 0) then begin
                      openr, cobun, conf.cobj, /get_lun, error=cerr
                      IF (cerr NE 0) THEN BEGIN
                          hdr = headfits(conf.cimg)
                          sobj = mrdfits(conf.sobj,1)
; Sometimes, an empty file is passed.  Fail gracefully if this happens
                          IF datatype(sobj) EQ 'STC' THEN BEGIN 
;    Next, call the calibration function
                              rotse_iii_usno_cal,hdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0]
;    if successful, write the cobj file
;;stop
                              IF (NOT fail) THEN BEGIN
                                  write_cobj, conf, ustat, ucal, hdr ; OUTSIDE
;    update the running stat log for database storage
                                  update_stats, conf, ustat, sobj, zpstr ;  OUTSIDE
; In order to make this more modular, I am inserting a function call here
; that will do any match structure and image processing necessary for
; real-time fast burst analysis.                  
                                  if (conf.domatch ne 0) then begin
                                      realtime_burst, conf, ustat, ucat ; OUTSIDE
; The next function call will update realtime match structures for patrol data
                                      update_sky_match, conf, hdr ; OUTSIDE
                                  endif
                                  ;; this is a hack for 3a oscillations
                                  if ((conf.statroot eq 'rotse3a') and $
                                      (ustat.pos_sigma gt 0.5)) then begin
                                      check_rotse3a_doughnuts,conf,ustat
                                  endif                                 

                              ENDIF ELSE BEGIN
                                  print, 'Catalog match failed.'
                                  make_sobjstat, conf, hdr, ustat
                                  update_stats, conf, ustat, sobj, zpstr, /sobjonly
;; DO THIS ONCE READY                                  
realtime_burst, conf, ustat, ucat, /sobjonly ; OUTSIDE
                              ENDELSE
;;stop

                          ENDIF 
                      ENDIF ELSE BEGIN
                          close, cobun
                          free_lun, cobun
                      ENDELSE 
                  endif
                  print, 'Sobjfile '+newfile+' finished.' 
              ENDELSE
;              loop = 0          ; turn off loop for testing
              if (do_stamp) then begin
                  openw,stamplun,conf.stampfile,/get_lun
                  free_lun,stamplun
              endif
          ENDWHILE   
      ENDELSE 
  ENDELSE 
END
  
