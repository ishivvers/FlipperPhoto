pro read_skydot_sql_new,ct,n,obs,verbose=verbose

   if (n_params(0) eq 0) then begin
       print,'Syntax: read_skydot_sql_new,ct,n,obs,verbose=verbose'
       return
   endif

   field=ct(n).field
   file='/rotse3/data0/rotse1/skydot/skydotID_'+field+'.sql'

   get_lun,fid
   openr,fid,file
   str=' '

   sbyte=ct(n).sbyte
   point_lun,fid,sbyte

   nobs=ct(n).n_points
   oneobs=create_struct('obj_id',0L,'frame_id',0L,'dra',0,'ddec',0,$
                        'mag',0.0,'err',0.0,'flags',0,'mjd',0.0d)
   obs=replicate(oneobs,nobs)

   for i=0,nobs-1 do begin
       readf,fid,str
       sarr=str_sep(str,';')
 
       obs(i).obj_id=sarr(0)
       obs(i).frame_id=sarr(1)
       obs(i).dra=sarr(2)
       obs(i).ddec=sarr(3)
       obs(i).mag=sarr(4)/1000.
       obs(i).err=sarr(5)/1000.
       obs(i).flags=sarr(6)

       if (keyword_set(verbose)) then begin
	print,i,' ',sarr(0),' ',sarr(4)/1000.,' ',sarr(6)
    endif

   endfor    

   close,fid
   free_lun,fid

   return
end
