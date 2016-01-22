PRO realtime_burst, cnf, ustat, ucat, sobjonly=sobjonly
;+
; FUNCTION: REALTIME_BURST
;
;;;;; SYNTAX: realtime_burst, cnf, st, cob, ucat
; SYNTAX: realtime_burst, cnf, st, ucat, sobjonly=sobjonly
;
; INPUTS: cnf: the idlpacman configuration structure
;         ustat: the cobj stat structure
;         cob: the calibrated object list
;         ucat: the usno catalog structure
;         sobjonly: called in the no-cobj loop. ignore the match structure!
;
; PURPOSE: this function is intended to be a wrapper for whatever processes
;          we want to run on calibrated object lists from images taken in 
;          response to a burst alert.  These will include (to start with):
;          writing html files and jpgs to spot-check the images
;          making or updating a match structure 
;          automatic identification of new/variable sources
; 
; REVISION HISTORY:
;     Created:   Don Smith   UM    11/16/01
;     Modified:  Don Smith   UM    08/07/02 - Deleted all html functions
;                Don Smith         08/20/02 - Added crop for grb region
;                Eli Rykoff  UM    08/26/03 - added automatic coadding
;                Eli Rykoff        01/19/04 - modified call to realtime_match
;                Eli Rykoff        02/23/04 - works with new/old match strs
;                Eli Rykoff        12/30/04 - adds files to filelist.txt
;                Sarah Yost  UM    01/25/05 - cleaning (cob isn't
;                                             used), adding a file
;                                             creation when it reaches
;                                             10 images with no cobj
;                                             produced, for cloudy response
;                Sarah Yost        02/11/05 - updating as downstream
;                                             changed with realtime_match
;                Sarah Yost        02/17/05 - adding followup coadds
;                                             (by 30s)
;                Eli Rykoff        12/08/05 - added /fast mode
; ===================================================================
;-

;;  sky = 0
  burstimage = 0
  followup = 0
  frac = 1.5
  nocal = 0
; These are tlas for realtime burst response
  goodtla = ['gsq','gsb','gsx','gsu','gss','gsl','ggg','ggi','ggu','ggf','gha','ghu','ghf','ghg','grs','giw','gir','gio','cou','xrp','xra','xat','gaw','gag','gar','ice','ict','tla','ant','att','anr']
  FOR i=0,n_elements(goodtla)-1 DO $
    IF (cnf.tla EQ goodtla[i]) THEN burstimage = 1

  folwtla = ['fup']
  FOR i=0,n_elements(folwtla)-1 DO $
    IF (cnf.tla EQ folwtla[i]) THEN followup = 1


  IF (followup) THEN BEGIN


      if ((ustat.nframe mod 30) eq 0 and (cnf.linkdir ne 'null')) then begin

          ;; it's coadding time - glob all the relevant cobj filenames
          cd, cnf.workdir
          parts = strsplit(ustat.fname,'_', /extract)

;; globbing has to be done by parts to make this work

          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string((ustat.nframe-30)/10,format='(i2.2)') + '[1-9]_cobj.fit'
          files_a=findfile(globstr,count=cnta)

          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string((ustat.nframe-30)/10+1,format='(i2.2)') + '?_cobj.fit'
          files_b=findfile(globstr,count=cntb)

          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string((ustat.nframe-30)/10+2,format='(i2.2)') + '?_cobj.fit'
          files_c=findfile(globstr,count=cntc)

          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string(ustat.nframe,format='(i3.3)') + '_cobj.fit'
          files_d=findfile(globstr,count=cntd)

;; it is now possible that ALL these have no cobj, as sobj cases get through


          if (cnta gt 0) then begin
              files = files_a
              if (cntb gt 0) then files = [files,files_b]
              if (cntc gt 0) then files = [files,files_c]
              if (cntd gt 0) then files = [files,files_d]
          endif else if (cntb gt 0) then begin
              files = files_b
              if (cntc gt 0) then files = [files,files_c]
              if (cntd gt 0) then files = [files,files_d]
          endif else if (cntc gt 0) then begin
              files = files_c
              if (cntd gt 0) then files = [files,files_d]
          endif else files = '' ;; doesn't matter about d-nothing to add up


          if (n_elements(files) ge 2) then begin

              coadd_names3,files,imagepath=cnf.imgdir,cobjpath=cnf.cobjdir,coaddname=coaddname
              cmd = 'mv ' + coaddname + ' ' + cnf.imgdir
              spawn,cmd
              cmd = 'ln -s ' + cnf.imgdir + '/' + coaddname + ' ' + cnf.linkdir
              spawn,cmd
          endif





      endif

  ENDIF

  ;; only continue if we have the correct tla AND it isn't a coadded image
  IF (((burstimage EQ 1) or (followup eq 1)) and (ustat.ncoadd eq 1)) THEN BEGIN

; Create or Update a match structrue
      cd, cnf.cobjdir
; If the match structure exists, then we need to append to it

      if not keyword_set(sobjonly) then begin

          ;; if it's a fup, we want to try the matchfup first
          ;; the idea is: if a burst matchfile has been made, we should use it
          ;; and append to it.  regmatch3_list will save it from the first name
          ;; in the structure, so it doesn't matter that the last files have a
          ;; different name.  On the other hand, if a burstmatch hasn't been
          ;; made, then we have to use the matchname with "fup" in it, since
          ;; that will be the first image in the match structure.
          mfound = 0
          use_match=cnf.match
          if (followup eq 1) then begin
              ;; matchfup is special: the fup- has been removed
              openr, mun, cnf.matchfup,/get_lun,error=merr
              if (merr eq 0) then begin
                  ;; use the matchfup
                  mfound = 1
                  use_match = cnf.matchfup
                  free_lun,mun
              endif
          endif
          if (mfound eq 0) then begin
              ;; this is for regular burstmatches OR fups when a burstmatch has
              ;; already been made
              openr,mun,cnf.match,/get_lun,error=merr
              if (merr eq 0) then begin
                  mfound = 1
                  free_lun,mun
              endif
          endif


          if (mfound eq 1) then begin
              m=mrdfits(use_match, 1)
              st=mrdfits(use_match, 2)

; print, 'read '+cnf.cobjdir+cnf.match
         
              if tag_exist(m,'nobs') then begin
                  allobs = lindgen(m.nobs)
                  nobs = m.nobs
                  nobj = m.nobj
              endif else begin
                  allobs = lindgen(n_elements(m.jd))
                  nobs = n_elements(m.jd)
                  nobj = n_elements(m.ra)
              endelse

              trg=find_targ(use_match, s=st[0], f=frac)
; Note: some kind of limits may have to be imposed, or this will
;       take way too long, or even crash.
              size_score = nobs * nobj
              if (size_score lt 500000l) then BEGIN
                  fail=0
                  regmatch3_list, m, st, namelist=cnf.cobj, /append, /over, /crop, $
                    limits=targ2lims(trg),fail=fail
; Make light curves and close-crop images if enough images have been recorded.
              ;;      realtime_match, m, st, idir=cnf.imgdir, bdir=cnf.bindir,
              ;;      target=trg

;; NOTE binary file is written through here - send conf through so it
;;                                            can look for the 1st image
                  if (fail eq 0) then begin
                      realtime_match,m,st,/docrop,bdir=cnf.bindir,target=trg, conf=cnf
                  endif else begin
                      print,'regmatch3_list failed'
                  endelse
              endif else begin
                  print,'Match structure too large-- not adding cobj file.'
              endelse
          ENDIF ELSE BEGIN 
; If not, we need to see if there are two cobj files so we can start one

              lscobjarr = findfile(cnf.rootnoseq+'*cobj.fit',count=ncobj)

              IF ncobj ge 2 THEN BEGIN 
                  ;; we need to check that the pointing is correct on these,
                  ;; and remove the ones that aren't.  Ugh.
                  bnds = find_targ(lscobjarr[0], f=frac)
                  gptarr=bytarr(ncobj)
                  for i=0l,ncobj-1 do begin
                      cal=mrdfits(lscobjarr[i],2)
                      if (bnds[0] gt cal.ra_low and $
                          bnds[0] lt cal.ra_high and $
                          bnds[1] gt cal.dec_low and $
                          bnds[1] lt cal.dec_high) then $
                        gptarr[i] = 1
                  endfor
                  h=where(gptarr eq 1,ncobj)
                  if (ncobj ge 2) then begin
                      lscobjarr=lscobjarr[h]

                      fail = 0
                      regmatch3_list, m, st, namelist=lscobjarr[0:1], /save, limits=targ2lims(bnds),fail=fail
                      if (fail eq 1) then print,'regmatch3_list failed'
                      ;; run the fast-finder -- if it's small enough
                      ;; (also set the fraction to 1.0)
                      trg=find_targ(m,s=st[0],f=1.0)
                      if (trg[2] lt 0.1 and fail eq 0 and n_elements(lscobjarr) eq 2) then begin
                          print,'Running realtime_match in fast mode'
                          realtime_match,m,st,bdir=cnf.bindir,target=trg,conf=cnf,/fast
                      endif
                  endif else begin
                      print,'WARNING: The pointing is NOT CORRECT on any burst response image.'
                      nocal = 1
                  endelse
              endif else begin
                  nocal = 1
              endelse


;;              ENDIF ELSE BEGIN
              if (nocal eq 1) then begin
; less than 2 cobj files, i.e., nothing is calibrating OR it hasn't
; reached that point yet

; test for the image index, if=10, make the "not calibrating" products
; if it's < 10, not worth it - wait till 1st 10 images are taken to
;                              see if something calibrates
; if it's > 10, then at 10 it also had < 2 cobj and already did this

                  if (ustat.nframe EQ 10) then begin
                      
                      realtime_nocal, ustat, cnf

                  endif

;;              ENDELSE
              endif

          ENDELSE

      endif else begin ;; sobjonly case, again test for frame=10, go do .bin

          if (ustat.nframe EQ 10) then begin
              realtime_nocal, ustat, cnf
          endif

      endelse



      ;; check if we want to do some coadding
      if ((ustat.nframe mod 10) eq 0 and (cnf.linkdir ne 'null') and (not followup)) then begin
          ;; it's coadding time - glob all the relevant cobj filenames
          cd, cnf.workdir
          parts = str_sep(ustat.fname,'_')
          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string((ustat.nframe-10)/10,format='(i2.2)') + '[1-9]_cobj.fit'
          files_a=findfile(globstr,count=cta)
          globstr = cnf.cobjdir + '/' + parts[0] + '_' + parts[1] + '_??' + $
                    string(ustat.nframe,format='(i3.3)') + '_cobj.fit'
          files_b=findfile(globstr,count=ctb)

          ;; we need at least one file from files_a to have a co-add...
          if (cta gt 0) then begin
              if (ctb gt 0) then $
                files = [files_a,files_b] $
              else $
                files = files_a

              if (n_elements(files) ge 2) then begin
                  coadd_names3,files,imagepath=cnf.imgdir,cobjpath=cnf.cobjdir,coaddname=coaddname
                  cmd = 'mv ' + coaddname + ' ' + cnf.imgdir
                  spawn,cmd
                  cmd = 'ln -s ' + cnf.imgdir + '/' + coaddname + ' ' + cnf.linkdir
                  spawn,cmd
              endif
          endif

      endif

  ENDIF else if (((burstimage eq 1) or (followup eq 1)) and (ustat.ncoadd gt 1)) then begin
      ;; we have a co-added burst frame.  Make subframes!

      if (ustat.trig_err lt 0.15) then begin
          use_rad = ustat.trig_err * 2.
          ;; for extra small error boxes
          if (use_rad lt 0.1) then use_rad = 0.1

          gen_rotse3_subimages,ustat.trig_ra,ustat.trig_dec,use_rad, $
            imagenames=[ustat.fname],oname=oname,fail=fail

          if (fail eq 0) then begin
              for i=0l,n_elements(oname)-1 do begin
                  cmd = 'cp ./image/' + oname + ' ' + cnf.bindir
                  spawn,cmd
                  
                  ;; and the other
                  parts=strsplit(oname[i],'\_c.fit',/extract,/regex)
                  cmd = 'cp ./prod/' + parts[0] + '_cobj.fit ' + cnf.bindir
                  spawn,cmd

                  ;; and touch the thumbcopy file (probably superfluous)
                  spawn,'touch '+ cnf.thumbfile

              endfor
          endif else begin
              print,'no subframes created.'
          endelse
      endif else begin
          print,'Error box too large for auto-subframes'
      endelse
  endif

  ;; update filelist if it's a burst image-- both regular and coadd
  if ((burstimage eq 1) or (followup eq 1)) then begin
      parts=strsplit(ustat.fname,'_',/extract)

      listname = cnf.cobjdir + '/' + parts[1] + '_' + strmid(parts[2],0,2) + '_filelist.txt'

      test=findfile(listname,count=ct)
      openw,lun,listname,/get_lun,/append
      if (ct eq 0) then begin
          ;; write the ra/dec/err
          printf,lun,string(ustat.trig_ra,format='(f12.7)') + ' ' + $
            string(ustat.trig_dec,format='(f12.7)') + ' ' + $
            string(ustat.trig_err,format='(f12.7)')
      endif
      ;; write the filename
      printf,lun,ustat.fname

      free_lun,lun

      ;; make a copy of this for the response copying
      cmd = 'cp ' + listname + ' ' + cnf.bindir
      spawn,cmd
  endif


  cd, cnf.workdir
END 
