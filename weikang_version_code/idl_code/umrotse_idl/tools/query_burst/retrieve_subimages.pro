pro retrieve_subimages,rac,decc,rad,fnames,pipepath=pipepath

if n_params() lt 4 then begin
    print,'syntax- retrieve_subimages,rac,decc,rad,fnames,pipepath=pipepath'
    return
endif

if n_elements(pipepath) eq 0 then pipepath = '/rotse/data/pipeline'


cfgfile = pipepath + '/idlpac.conf'
test=findfile(cfgfile,count=count)
if (count ne 1) then begin
    print,'Could not find config file: ',cfgfile
    return
endif

conf = create_struct('test', 0)
readcol,cfgfile,tag,value,format='(a,a)'
for i=0,n_elements(tag)-1 do begin
    conf = create_struct(conf,tag[i], value[i])
endfor

if (not tag_exist(conf, 'bindir')) then begin
    print,'bindir not set in config file'
    return
endif
if (not tag_exist(conf, 'thumbfile')) then begin
    print,'thumbfile not set in config file'
    return
endif
if (not tag_exist(conf, 'workdir')) then begin
    print,'workdir not set in config file'
    return
endif


mvcmd = "mv "

cd,conf.workdir
for i=0l,n_elements(fnames)-1 do begin
    fail = 0
    make_rotse3_subimage,fnames[i],racent=rac,deccent=decc,degrad=rad,fail=fail,oname=oname

    if (fail eq 1) then begin
        print,'Could not create subimage for ',fnames[i]
    endif else begin
        dirparts=strsplit(oname,'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
        
        namebase = parts[0] + '_' + parts[1] + '_' + parts[2]

        mvcmd = mvcmd + ' ' + namebase+'_c.fit ' + namebase+'_cobj.fit '
 
    endelse
endfor

mvcmd = mvcmd + ' ' + conf.bindir
spawn,mvcmd
cmd = "touch " + conf.thumbfile
spawn,cmd

return
end

