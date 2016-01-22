; build_usno_db2:
;   You first need to run make_usno_dbs.pro to create the basic databases
;    Unfortunately, due to file size limitations as well as idl database limits,
;     the usno database needs to be spread into a number (8) sub-databases
;
;      extract_usno_db will take care of the extraction
;
;  10-01: Eli Rykoff
;

PRO build_usno_db2, basename,maglimit

  if N_params() eq 0 then begin
      print,'Syntax- build_usno_db, basename, maglimit'
      return
  endif

  rotse_setup

  path = '/rotse2/data0/products/usno/'
  numzones = 24
  zones = ['0000','0075','0150','0225','0300','0375','0450','0525','0600', $
           '0675','0750','0825','0900','0975','1050','1125','1200','1275', $
           '1350','1425','1500','1575','1650','1725']

  obj_to_process = 500000

  t = systime(1)

  !priv = 2

  for i=0,numzones-1 do begin
      ; Count the number of objects in the zone
      acc_file = path + 'zone' + zones[i] + '.acc'
      openr,lun,acc_file,/get_lun
      junk = 0.0
      offset = 0l
      obj = 0l
      while (not eof(lun)) do begin
          readf,lun,junk,offset,obj
      endwhile
      total_obj = offset+obj-1   ; The total is the last offset + last num_obj - 1
      free_lun,lun

      cat_file = path + 'zone' + zones[i] + '.cat'
      print,cat_file,total_obj
      openr,lun,cat_file,/get_lun,/swap_if_little_endian

      ; Now, split into chunks of obj_to_process 
      while (total_obj gt 0) do begin
          obj_to_read = 0l
          if (obj_to_process le total_obj) then begin
              obj_to_read = obj_to_process
              total_obj = total_obj - obj_to_process
          endif else begin
              obj_to_read = total_obj
              total_obj = total_obj - obj_to_read
          endelse

          raw_data_chunk = replicate(long(0),3,obj_to_read)
          ra_array=dblarr(obj_to_read)
          dec_array=dblarr(obj_to_read)
          bmag_array=fltarr(obj_to_read)
          rmag_array=fltarr(obj_to_read)
          print,'Reading ',obj_to_read,' Elements'
          readu,lun,raw_data_chunk

          ra_array = reform(raw_data_chunk(0,*))   ; Don't convert
	  dec_array = reform(raw_data_chunk(1,*))

          rmag_array = abs((raw_data_chunk(2,*) mod 1000)/10.0)
          bmag_array = abs(((raw_data_chunk(2,*) mod 1000000)/1000)/10.0)

          print,'Cropping to ',maglimit,' magnitude'
          objects_to_insert = where(rmag_array le maglimit)

	  ; Crop the lists
	  ra_array = ra_array(objects_to_insert)
	  dec_array = dec_array(objects_to_insert)
          bmag_array = bmag_array(objects_to_insert)
	  rmag_array = rmag_array(objects_to_insert)

	  ra_conv = double(ra_array) / (3600d * 100d)
	  dec_conv = (double(dec_array)) / (3600d * 100d) - 90d 

	  plot,ra_conv,dec_conv,psym=3,/ynozero

	  ; Compress the magnitudes
	  bmag_int = intarr(n_elements(bmag_array))
          rmag_int = intarr(n_elements(rmag_array))
          
          bmag_int = fix(round(bmag_array * 10))
          rmag_int = fix(round(rmag_array * 10))
	 
          ; Create the Leaf IDs

	  print,'Getting leaf ids with leaf_depth = ', !usno_db_leaf_depth
	  htmLookupRadec,ra_conv,dec_conv, !usno_db_leaf_depth, leafids_coarse

          print,'Getting leaf ids with leaf depth = ', !usno_leaf_depth
          htmlookupradec,ra_conv,dec_conv, !usno_leaf_depth, leafids_fine

	  ; Figure out which databases...
	  unique_dbs = leafids_coarse[rem_dup(leafids_coarse)]

	  add_arrval, unique_dbs, updated_dbs

	  for j=0l, n_elements(unique_dbs) - 1 do begin
	     dbname = string(basename + '_' + strtrim(unique_dbs(j),2))
	     these_objs = where(leafids_coarse eq unique_dbs[j])

	      print,'Putting ',n_elements(these_objs),' objects into database ',dbname

	      dbopen,dbname,1

	      dbbuild, $
                 long(leafids_fine[these_objs]), $
	         ra_array[these_objs], $
	         dec_array[these_objs], $
	         rmag_int[these_objs], $
	         bmag_int[these_objs], $
	         /noindex

           endfor

           raw_data_chunk = 0
          
      endwhile   ; chunks of the file
      free_lun,lun
  endfor ;through the zones
 
  ; Now do the indexing
  updated_dbs = updated_dbs[rem_dup(updated_dbs)]
  for k=0l,n_elements(updated_dbs)-1 do begin
     dbname = string(basename + '_' + strtrim(updated_dbs(k),2))
     print,'Indexing ', dbname
     dbopen, dbname,1
     dbindex
  endfor


  print,(systime(1)-t)/60.,' minutes'

  !priv = 0

  return
END 
