FUNCTION check_pair, chead, ptname
  pair = 0
  cmjd = sxpar(chead, 'MJD')
  phead = headfits(ptname)
  pmjd = sxpar(phead,'MJD')
  too_long = sxpar(phead, 'EXPTIME')+sxpar(chead, 'EXPTIME')
  delay = (cmjd - pmjd)*24.*60.*60.
  IF delay LT too_long AND delay GT -too_long THEN pair = 1
  return, pair
END 

FUNCTION test_name, co, cohead, num, prtn 
  test = 0
  prtn = co.cobjdir + "/" + co.rootnoseq + $
                  string(co.nseq+num,format="(i3.3)")+'_cobj.fit'
  openr, plun, prtn, /get_lun, error=perr
  IF perr EQ 0 THEN BEGIN
      close, plun
      free_lun, plun
      test = check_pair(cohead, prtn)
  ENDIF 
  return, test
END 

FUNCTION find_partner, c, currhead, pname
  found = 0
  IF c.nseq GT 1 THEN found = test_name(c, currhead, -1, pname)
  IF found EQ 0 THEN $
      found = test_name(c, currhead, 1, pname)
  return, found
END

PRO update_sky_match, cnf, currhd
  ; First, only proceed if this is an acceptable tla
  define_target_tlas,target_tlas
  goodtlas = ['sky','skc','sks'] ; for now, just sky patrols.  May want to add more later.
  chk = where(goodtlas eq cnf.tla, proceed)
  chk2 = where(target_tlas eq cnf.tla, proceed2)
  if (proceed gt 0 or proceed2 gt 0) then begin 
      ;; Before proceeding, verify matchdirectory name
      IF tag_exist(cnf, 'MATCHDIR') THEN matchdir=cnf.matchdir $
      ELSE matchdir = !match_archive_path
      ;; Now, on to the data.
      stuff = find_partner(cnf, currhd, partner)
      IF stuff THEN BEGIN 
          ;; If there's a match, continue on
          ;; Otherwise, exit without changing anything
          ;; Check to see if a match structure file already exists

          m = mrdfits(matchdir+'/'+cnf.match,1)
          ;; Now update the match structure
          nlist = [partner, cnf.cobj]

          ;; check to see if these files pass the quality checks
          addtomatch = 1
          for i=0l,n_elements(nlist)-1 do begin
              cal=mrdfits(nlist[i],2)
              ;; check pos_sigma
              if (cal.pos_sigma gt 0.3) then addtomatch = 0
              ;; other checks can be added here
          endfor
          
          if (addtomatch) then begin
              if (proceed gt 0) then begin
                  ;; a sky patrol field to save, etc, etc
                  if datatype(m) eq 'STC' then begin
                      st = mrdfits(matchdir+'/'+cnf.match,2)
                      regmatch3_list, m, st, /pair, namelist=nlist, /archive, $
                        /append, /over, archdir=matchdir
                  endif else BEGIN
                      regmatch3_list, m, st, /pair, namelist=nlist, /archive, archdir=matchdir
                  endelse 
                  ;;  Insert transient checks here.
                  print,'Looking for transients...'
                  appendobs=[m.nobs-2,m.nobs-1]
;;              find_new_transients,m,st,trans,appendobs=appendobs,conf=cnf,/output
                  find_new_transients2,m,st,trans,appendobs=appendobs,conf=cnf,/output
              endif else begin
                  ;; a target field just for variable monitoring
                  regmatch3_list, m, st, /pair, namelist=nlist
              endelse
              print,'Checking variable monitor list...'
              varmonitor_update_struct,m
          endif
      ENDIf
  endif
END
