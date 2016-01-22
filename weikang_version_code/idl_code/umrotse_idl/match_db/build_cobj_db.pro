pro build_cobj_db,filelist,basename=basename,caldb=caldb

if n_params() eq 0 then begin
    print,'Syntax - build_cobj_db, filelist, basename=basename, caldb=caldb'
    print,'All databases need to be created ahead of time'
    print,' If basename,caldb are not spefified, rotse_setup vars are used'
    return
endif

  rotse_setup

  if (not keyword_set(basename)) then basename = !match_dbase_name
  if (not keyword_set(caldb)) then caldb = !cobj_dbase_name

  if (!priv ne 2) then begin
      print,'!priv must be 2 to run this program; it will reset to 0 after'
      return
  endif

  updated_dbs = -1
  
  openr,lun,filelist,/get_lun
  n=1
  name=''
  while not eof(lun) do begin
      readf,lun,name,format='(a60)'
      info=str_sep(name," ")
      name=info(0)
      print,""
      ; Add some error checking to confirm cobj file types
      nameparts = str_sep(name,'_')
      if (n_elements(nameparts) eq 4) then begin
        if (nameparts[3] eq 'cobj.fit') then begin

          print,"Adding file:",name, "  Number:",n

          cobj=mrdfits(name,1)
          cal =mrdfits(name,2)

          add_cobj_to_db,cobj,cal,basename,caldb,updated_dbs=updated_dbs

          n=n+1
        endif
      endif
  endwhile

  ; Index the databases that have been updated

  if (n_elements(updated_dbs) gt 1) then begin
    updated_dbs = updated_dbs[1:(n_elements(updated_dbs)-1)]   ; Remove the -1
    unique_dbs = updated_dbs[rem_dup(updated_dbs)]
    for i=0l,n_elements(unique_dbs)-1 do begin
        dbname = basename + '_' + strtrim(unique_dbs[i],2)
      
        print,'Indexing database ', dbname

        dbopen,dbname,1
        dbindex
        dbclose
    endfor
  endif
  !priv = 0


return
end
