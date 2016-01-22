pro add_cobj_to_db,cobj_str,cal_str,basename,caldb,retval=retval,updated_dbs=updated_dbs

if n_params() eq 0 then begin
    print,'Syntax- add_cobj_to_db,cobj_str,cal_str,objdb,caldb,retval=retval'
    return
endif

  calc_cobj_key,cal_str.filename,cobj_key_1,cobj_key_2

  ; First check if it has already been added

  cond = 'key_1 = ' + string(cobj_key_1)+', key_2 = ' + string(cobj_key_2)
  dbopen,caldb,0
  entered_cobj = dbfind(cond, count = count,/silent)
  if (count > 0) then begin
      print,'Cobj file from ',cal_str.filename,' Already in database ',caldb
      dbclose
      retval = -1
      return
  endif

  ; We should add some quality cuts...decide what's good, but
  ;  add the cobj to the database with a flag!

  ; Add the relevant information to the cal database
  dbopen,caldb,1
  dbbuild, $
    cal_str.filename, $
    cobj_key_1, $
    cobj_key_2, $
    cal_str.mjd, $
    cal_str.pos_sigma, $
    cal_str.zp_offset, $
    cal_str.zp_sigma, $
    byte(0)     ; Is /noindex a mistake?
  
  dbclose

 
  ; <we could do a search if we have the index>
  ; Find out which number we just built
  dbopen,caldb,0
  num_entries = db_info('entries',caldb)
  dbclose

  ; Get the leaf_ids for our guys

  print,'Getting leaf ids with leaf_depth = ', !match_db_leaf_depth
  htmLookupRadec,double(cobj_str.ra),double(cobj_str.dec), $
        !match_db_leaf_depth,leafids_coarse

  print,'Getting leaf ids with leaf_depth = ', !match_leaf_depth
  htmLookupRadec,double(cobj_str.ra),double(cobj_str.dec), $
        !match_leaf_depth,leafids_fine

  ; Insert the stuff into the database

  ; Conversion:
  ;   ra_long = ra * 3600 * 100
  ;   dec_long = dec * 3600 * 100
  ;   mag_int = mag * 1000
  ;   magerr_int = mag_err * 1000
  
  ra_long = round(cobj_str.ra * 3600d * 100d)
  dec_long = round((cobj_str.dec + 90d) * 3600d * 100d)
  
  mag_int = intarr(n_elements(cobj_str))
  magerr_int = intarr(n_elements(cobj_str))
  for i=0l,n_elements(cobj_str)-1 do begin
      if (cobj_str(i).m lt 0.0) or (cobj_str(i).m gt 30.0) then begin
          mag_int[i] = -1
      endif else begin
          mag_int[i] = fix(round(cobj_str(i).m * 1000.0))
      endelse

      if (cobj_str(i).merr lt 0.0) or (cobj_str(i).merr gt 30.0) then $
        magerr_int(i) = -1 $
      else magerr_int(i) = fix(round(cobj_str(i).merr * 1000.0))
  endfor
    
  ; Make compatibility for older cobj files
  numobj = n_elements(cobj_str)

  if tag_exist(cobj_str,'rflags') then begin 
      rflags = cobj_str.rflags
  endif else rflags = replicate(byte(0),numobj)

  if tag_exist(cobj_str,'msys200') then begin
      msys200 = cobj_str.msys200
  endif else msys200 = replicate(byte(0),numobj)

  if (size(cobj_str.flags,/type) eq 1) then begin
      flags = cobj_str.flags
  endif else flags = byte(cobj_str.flags)

  ; Figure out which databases
  unique_dbs = leafids_coarse[rem_dup(leafids_coarse)]

  add_arrval,unique_dbs,updated_dbs

  for i=0l,n_elements(unique_dbs)-1 do begin

      dbname = basename + '_' + strtrim(unique_dbs(i),2)
      these_objs = where(leafids_coarse eq unique_dbs[i])

      print,'Putting ',n_elements(these_objs),' objects into database ',dbname

      dbopen,dbname,1
      dbbuild, $
        long(leafids_fine[these_objs]), $
        replicate(num_entries,n_elements(these_objs)), $ ; Pointer to cobj db
        ra_long[these_objs], $
        dec_long[these_objs], $
        mag_int[these_objs], $
        magerr_int[these_objs], $
        flags[these_objs], $
        rflags[these_objs], $
        msys200[these_objs], $
        /noindex
      
      dbclose
      
  endfor

  retval = 0

return
end
