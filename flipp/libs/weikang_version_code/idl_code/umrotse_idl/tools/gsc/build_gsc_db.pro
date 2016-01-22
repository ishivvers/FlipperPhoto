PRO build_gsc_db,basename

  if N_params() eq 0 then begin
     print,'Syntax- build_gsc_db, basename'
      return
  endif

  rotse_setup

  path = '/rotse4/data0/gsc/'

  dbname = !gsc_dbname

  chunksize = 500000

  ; Prepare Database

  !priv = 2

  spawn,"pwd",cwd
  spawn,"printenv ZDBASE",zdbase
  cd,zdbase[0]

  t = systime(1)

  for i=0,1 do begin
      if (i eq 0) then fit_file = path + 'gsc_north.fit' else fit_file = path + 'gsc_south.fit'
  
      gcat = mrdfits(fit_file,1)

      numobj = n_elements(gcat.ra)
      index = 0l

      while (index lt numobj) do begin
          if ((numobj - index) gt chunksize) then begin
              range = lindgen(chunksize) + index
          endif else begin
              range = lindgen(numobj - index) + index
          endelse
          index = max(range) + 1
          
          ra_array = double(gcat.ra[range])
          dec_array = double(gcat.dec[range])
          mag_array = double(gcat.mag[range])

          plot,ra_array,dec_array,psym=3,/ynozero

          ; Create the Leaf IDs

          print,'Getting leaf ids with leaf_depth = ', !usno_db_leaf_depth
          htmLookupRadec, ra_array, dec_array, !usno_db_leaf_depth, leafids_coarse
          
          print,'Getting leaf ids with leaf_depth = ', !usno_leaf_depth
          htmlookupradec, ra_array, dec_array, !usno_leaf_depth, leafids_fine

          ; Figure out which databases...
          unique_dbs = leafids_coarse[rem_dup(leafids_coarse)]

          add_arrval, unique_dbs, updated_dbs

          ra_mod = long(ra_array * 3600. * 100.)
          dec_mod = long((dec_array + 90.) * 3600. * 100.)
          h = where(mag_array gt 20.0,count)
          mag_mod = fix(mag_array * 100.)
          if (count gt 0) then begin
              mag_mod(h) = 0
          endif
              
          for j=0l, n_elements(unique_dbs) - 1 do begin
              dbname = string(basename + '_' + strtrim(unique_dbs(j),2))
              these_objs = where(leafids_coarse eq unique_dbs[j])
              
              print, 'Putting ',n_elements(these_objs),' objects into database ', dbname 
    
              dbopen,dbname,1
              dbbuild, $
                long(leafids_fine[these_objs]), $
                ra_mod[these_objs], $
                dec_mod[these_objs], $
                mag_mod[these_objs], $
                /noindex
          endfor
      endwhile
      print,(systime(1)-t)/60.,' minutes'
  endfor


  ;Now do the indexing
  updated_dbs = updated_dbs[rem_dup(updated_dbs)]
  for k=0l, n_elements(updated_dbs)-1 do begin
      dbname = string(basename + '_' + strtrim(updated_dbs(k),2))
      print,'Indexing ', dbname
      dbopen,dbname,1
      dbindex
  endfor
  
  print,(systime(1)-t)/60.,' minutes'

  !priv = 0

  return
END 
