pro make_patrol_dbs, basename, actual_path, dbd_proto, makelinks=makelinks,noprompt=noprompt

if n_params() eq 0 then begin
   print, 'syntax - make_patrol_dbs, basename, actual_path, dbd_proto, makelinks=makelinks'
   return
endif

print,'This program will annihilate each database...and will ask you each time!'

ind = long((!match_db_leaf_depth + 1) * 2 + 1)
bottom_id = 2l^ind


spawn,"pwd",cwd
spawn,"printenv ZDBASE",zdbase
cd,zdbase[0]

if keyword_set(noprompt) then begin
  ans = ' '
  print,'Are you SURE you want to recreate _all_ the databases automatically?'
  read, ans, $
     prompt = 'If so, type "YES": '
  if (ans ne 'YES') then begin
     print,'Exiting now.'
     return
  endif
endif


for i = bottom_id, (2*bottom_id - 1l) do begin
   dbname = basename + '_' + strtrim(i,2)

   ; Generate the .dbd file
   openw,wlun,dbname+'.dbd',/get_lun
  
   printf,wlun,''
   printf,wlun,'#title'
   printf,wlun,'Match Database '+dbname
   printf,wlun,''

     start_copying = 0
     read_string = ''
     openr,rlun,dbd_proto,/get_lun
     while (not eof(rlun)) do begin
       readf,rlun,read_string
       if (start_copying) then begin
          printf,wlun,read_string
       endif else begin
          if (read_string eq '#maxentries') then begin
             printf,wlun,read_string
             start_copying = 1
          endif
       endelse
     endwhile

     free_lun,rlun

   free_lun,wlun


   make_single_db,dbname,actual_path,makelink=makelinks,noprompt=noprompt

endfor


cd,cwd[0]

return
end
