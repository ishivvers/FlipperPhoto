pro make_single_usno_db,dbname,actual_path,makelink=makelink,noprompt=noprompt

if n_params() eq 0 then begin
    print,'syntax - make_single_usno_db,dbname, actual_path, makelink=makelink'
    print,' There must be a .dbd file in the ZD_BASE directory.'
    print,' Only run this guy once, or it will delete the database!!'
    print,' It will also move the database files and create a link to them'
    return
endif


orig_priv = !priv
!priv = 0

print,'This program will create a new database called ', dbname
print,'Please be aware that any information there will be _deleted_'
print
print,'Are you sure you want to go through with this?'
print,'If yes, then input the value to set !priv, which must be "2"'

if (not keyword_set(noprompt)) then begin
 ans = ' '
 read, ans, $
   prompt='Please input the new value for !priv: '
 if (ans ne '2') then begin
     print,'Not creating new database'
     !priv = orig_priv
     return
 endif
endif else begin
 ans = '2'
endelse


a=0
reads,ans,a
!priv = a

spawn,"pwd",cwd
spawn,"printenv ZDBASE",zdbase
cd,zdbase[0]

dbcreate, dbname, 1, 1

!priv = orig_priv


if (keyword_set(makelink)) then begin
    cmd = 'mv ' + dbname + '.dbf ' + actual_path
    spawn, cmd
    cmd = 'chmod 664 ' + actual_path + '/' + dbname + '.dbf'
    spawn, cmd
    cmd = 'ln -s ' + actual_path + '/' + dbname + '.dbf ' + dbname + '.dbf'
    spawn, cmd

    cmd = 'mv ' + dbname + '.dbx ' + actual_path
    spawn, cmd
    cmd = 'chmod 664 ' + actual_path + '/' + dbname + '.dbx'
    spawn, cmd
    cmd = 'ln -s ' + actual_path + '/' + dbname + '.dbx ' + dbname + '.dbx'
    spawn, cmd

endif

cd,cwd[0]

return 
end



