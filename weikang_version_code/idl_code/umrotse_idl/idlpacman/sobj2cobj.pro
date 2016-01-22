; *****************************************************************************
; *****************************************************************************
;
; This program will take an sobj file and create a cobj file. 
;
; Modification history
;     CREATED: Don Smith   UM   09/03/02 
; *****************************************************************************


; *****************************************************************************
; augment_conf, c
; 
; This function adds certain fields to the structure that we'll need later
; *****************************************************************************
PRO augment_conf, c, idr
  c = create_struct(c, 'cobj', 'blank')
  c = create_struct(c, 'cimg', 'blank')
  c = create_struct(c, 'tla', 'blk')
  c = create_struct(c, 'grbid', 'blank')
  c = create_struct(c, 'root', 'blank')
  c = create_struct(c, 'rootnoseq', 'blank')
  c = create_struct(c, 'date', 'blank')
  c = create_struct(c, 'rac', 0.0)
  c = create_struct(c, 'decc', 0.0)
  c = create_struct(c, 'rotv', 3)
  c = create_struct(c, 'imfile', 'blank')
  c = create_struct(c, 'imdir', idr)  
  c = create_struct(c, 'sobjdir', './')   
END

; *****************************************************************************
; fill_struct, c, file, error
;
; This function takes a given cobj file and fills in various fields of the 
; conf structure that will be useful for various programs.
; *****************************************************************************
PRO fill_struct, c, file, error, hedr
  error = 0
  path = str_sep(file, '/')
  i = n_elements(path)
  nprts = str_sep(path[i-1], '_')
  FOR j=1,i-2 DO c.sobjdir = c.sobjdir + path[j] + '/'
  c.tla = strmid(nprts[1], 0, 3)
  c.date = nprts[0]
  c.grbid = nprts[1]
  c.root = nprts[0]+'_'+nprts[1]+'_'+nprts[2]
  c.rootnoseq = nprts[0]+'_'+nprts[1]+'_'+strmid(nprts[2],0,2)
  c.cimg = c.imdir+'/'+c.root+'_c.fit'
  c.cobj = c.root+'_cobj.fit'

  ; check that sobjfile and _c file exist
  test=findfile(c.sobj,count=scount)
  test=findfile(c.cimg,count=ccount)
  if (scount eq 0) then begin
      print,'File '+c.sobj+' does not exist.'
      error = 1
  endif else if (ccount eq 0) then begin
      print,'File '+c.cimg+' does not exist.'
      error = 1
  endif else begin
      hedr=headfits(c.cimg)
      ofdc = sxpar(hedr,'offstdec')
      mtdc = sxpar(hedr,'mountdec')
      mtra=sxpar(hedr,'mountra')
      ofra = sxpar(hedr,'offstra')
      cfac = cos(mtdc * !DTOR)
      c.decc = mtdc + ofdc
      c.rac = mtra + ofra/cfac
      IF (ofdc GT 1.0 OR ofdc LT -1.0) THEN c.rotv = 1
  endelse
END

; *****************************************************************************
; Begin main program
PRO sobj2cobj, sobj, imdir, nomod=nomod

  IF n_params() LT 2 THEN $
    print, "Syntax: sobj2cobj, sobj, imdir, nomod=nomod" $
  ELSE BEGIN 
; Check to make sure that the catalog path has been set
      spawn, 'printenv ZDBASE', test
      IF (strlen(test[0]) LT 10) THEN $
        print, 'Error: environment variable ZDBASE not set.' $
      ELSE BEGIN 
          conf = create_struct('sobj',sobj)
          augment_conf, conf, imdir
          fill_struct, conf, sobj, ferr, hdr
          IF ferr EQ 0 THEN BEGIN 
              sobjst = mrdfits(sobj,1) 
;    Next, call the calibration function
              rotse_iii_usno_cal,hdr,sobjst,ucat,ucal,ustat,fail=fail,/readusno
;    if successful, write the cobj file
              IF (NOT fail) THEN BEGIN
                  write_cobj, conf, ustat, ucal, hdr, nomod=nomod
              ENDIF 
          ENDIF 
      ENDELSE 
  ENDELSE 
END
  
