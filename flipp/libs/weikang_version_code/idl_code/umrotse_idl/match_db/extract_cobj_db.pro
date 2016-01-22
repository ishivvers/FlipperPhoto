pro extract_cobj_db,rac,decc,radius,obs_list,basename=basename,caldb=caldb

if n_params() eq 0 then begin
    print,'Syntax - extract_cobj_db,rac,decc,radius,obj_list,basename=basename,caldb=caldb'
    print,'If basename, caldb are not specified, the rotse_setup variables are used'
    return
endif

  rotse_setup

  if (not keyword_set(basename)) then basename = !match_dbase_name
  if (not keyword_set(caldb)) then caldb = !cobj_dbase_name

  obs = create_struct('ra', 0d, 'dec', 0d, 'm', 0.0, 'merr', 0.0, 'mjd', 0d, 'cobj',0l, 'key_2', 0l)
  obs_list=0

  ; First find which database(s) we need

  htmIntersectRadec, double(rac), double(decc), double(radius), $
    !match_db_leaf_depth, dbid_list

  htmIntersectRadec, double(rac), double(decc), double(radius), $
    !match_leaf_depth, leafid_list


  for i=0l,n_elements(dbid_list)-1 do begin
    dbname = basename + '_' + strtrim(dbid_list[i],2)

    dbopen,dbname+','+caldb,0
    for j=0l,n_elements(leafid_list)-1 do begin
      cond = 'leaf_id = '+string(leafid_list[j])
      temp_ids = dbfind(cond,count=count,/silent)
      if (count ne 0) then begin
          add_arrval,temp_ids,ids
      endif
    endfor

    ; Need to make sure some objects are found!

    if (n_elements(ids) gt 0) then begin
      names='ra_long,dec_long,mag_int,magerr_int,mjd,cobj_entry,key_2'
      dbext,ids,names,ra_long,dec_long,mag_int,magerr_int,mjd,cobj_entry,key_2

      temp_obs_list = replicate(obs,n_elements(ids))

      temp_obs_list.ra = double(ra_long) / (3600d * 100d)
      temp_obs_list.dec = double(dec_long) / (3600d * 100d) - 90d
      temp_obs_list.m = float(mag_int) / 1000.0
      temp_obs_list.merr = float(magerr_int) / 1000.0
      temp_obs_list.mjd = mjd
      temp_obs_list.cobj = cobj_entry
      temp_obs_list.key_2 = key_2

      if (obs_list eq 0) then begin
         obs_list = temp_obs_list
      endif else begin
         concat_structs,temporary(obs_list),temporary(temp_obs_list),temp
         obs_list = temp
      endelse
    endif

    dbclose

  endfor

  ; Now we need to do a close_match_radec to crop off the extra guys

  if n_elements(obs_list) gt 0 then begin
    print,'Found ', n_elements(obs_list),' observations in the triangles'
   ; need to check on ep units
    close_match_radec,obs_list.ra,obs_list.dec,rac,decc,m1,m2,radius, $
       n_elements(obs_list),miss1,/silent

    if (m1[0] ne -1) then begin
      obs_list=obs_list[m1]
      print,'Found ',n_elements(m1),' observations in the specified radius'
    endif else begin
      obs_list = 0
      print,'No observations found in the region.'
    endelse
  endif

return

end
