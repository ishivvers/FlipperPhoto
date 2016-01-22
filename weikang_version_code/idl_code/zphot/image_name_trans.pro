pro image_name_trans,inputname,outnamest,noimproddir=noimproddir

if n_params() eq 0 then begin
  print,'Syntax- image_name_trans,inputname,outnamest,noimproddir=noimproddir'
  return
endif

imagenamest={ori:'', dir: '', root:'', cimg:'',sobj:'',cobj:'', cwcs:'', cnew:'', ctwp:'', cfwp:'', ctcv:'', cfcv:'', ctsb:'', cfsb:'', sobjdir:'./' }

dir=strmid(inputname[0],0,strpos(inputname[0],'/',/REVERSE_SEARCH))
imagedir=''
proddir=''
if strmid(dir,strlen(dir)-5,5) eq 'image' then begin
  dir=strmid(dir,0,strlen(dir)-5)
  imagedir='image/'
  proddir='prod/'
endif
if strmid(dir,strlen(dir)-4,4) eq 'prod' then begin
  dir=strmid(dir,0,strlen(dir)-4)
  imagedir='prod/'
  proddir='dir/'
endif
if dir eq '' or dir eq '.' then dir='./'
if strmid(dir,strlen(dir)-1,1) ne '/' then dir=dir+'/'
if keyword_set(noimproddir) then begin
  imagedir=''
  proddir=''
endif

imagenamest.dir=dir
imagenamest.ori=inputname[0]
;dirparts1=strsplit(inputname[0],'/',/extract)
;imagename=dirparts1[n_elements(dirparts1)-1]
;another option to get imagename
imagename=strmid(inputname[0],strpos(inputname[0],'/',/REVERSE_SEARCH)+1)
;print,imagename

strreplace,imagename,'_c.fit',''
strreplace,imagename,'_sobj.fit',''
strreplace,imagename,'_cobj.fit',''
strreplace,imagename,'_cnew.fit',''
strreplace,imagename,'_cwcs.fit',''
strreplace,imagename,'_ctwp.fit',''
strreplace,imagename,'_cfwp.fit',''
strreplace,imagename,'_ctcv.fit',''
strreplace,imagename,'_cfcv.fit',''
strreplace,imagename,'_ctsb.fit',''
strreplace,imagename,'_cfsb.fit',''
strreplace,imagename,'.fit',''
imagenamest.root=imagename

imagenamest.cimg=dir + imagedir + imagenamest.root + '_c.fit'
imagenamest.sobj=dir + proddir  + imagenamest.root + '_sobj.fit'
imagenamest.cobj=dir + proddir  + imagenamest.root + '_cobj.fit'
imagenamest.cnew=dir + imagedir + imagenamest.root + '_cnew.fit'
imagenamest.cwcs=dir + proddir  + imagenamest.root + '_cwcs.fit'
imagenamest.ctwp=dir + imagedir + imagenamest.root + '_ctwp.fit'
imagenamest.cfwp=dir + imagedir + imagenamest.root + '_cfwp.fit'
imagenamest.ctcv=dir + imagedir + imagenamest.root + '_ctcv.fit'
imagenamest.cfcv=dir + imagedir + imagenamest.root + '_cfcv.fit'
imagenamest.ctsb=dir + imagedir + imagenamest.root + '_ctsb.fit'
imagenamest.cfsb=dir + imagedir + imagenamest.root + '_cfsb.fit'

outnamest=imagenamest

end
