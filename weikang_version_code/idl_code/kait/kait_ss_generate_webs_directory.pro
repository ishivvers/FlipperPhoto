pro kait_ss_generate_webs_directory,fieldname,workdir=workdir

;if n_params() eq 0 then begin
;    print,'kait_generate_webs_directory,workdir=workdir'
;    return
;endif

respdir='/kait/web/response/'
if not keyword_set(workdir) then workdir='./'

subfilenames=findfile(workdir+'*.sub.fit')
nf=n_elements(subfilenames)

if subfilenames[0] eq '' then exit

for i=0,nf-1 do begin
  ;print,subfilenames[i]
  strs=strsplit(subfilenames[i],'/')
  field=strmid(subfilenames[i],strs[n_elements(strs)-1],strlen(subfilenames[i]))
  strreplace,field,'_001.sub.fit',''
  print,'working on field : ',field,'  ',i+1,' of ',nf
  kait_ss_generate_webs,field,workdir=workdir
endfor

cd,workdir

end
