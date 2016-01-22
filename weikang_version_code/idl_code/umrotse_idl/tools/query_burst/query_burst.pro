pro query_burst,name,ra,dec,pipepath=pipepath

if n_params() eq 0 then begin
    print,'syntax- query_burst,name,ra,dec,pipepath=pipepath'
    return
endif


matchrad = 3.0  ;; pixels

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

namebase = '*_' + name

;; now we need to find the match structure
mtname = find_rotse3_matchfile(name,fail=fail)
if (fail eq 1) then begin
    print,'Match structure not found.  Cannot continue.'
    return
endif


;; we have the match file...look for our object
mt = mrdfits(mtname, 1)
sts = mrdfits(mtname, 2)

if tag_exist(mt,'nobs') then begin
    allobs = lindgen(mt.nobs)
    allobj = lindgen(mt.nobj)
    nobs = mt.nobs
    nobj = mt.nobj
endif else begin
    allobs = lindgen(n_elements(mt.jd))
    allobj = lindgen(n_elements(mt.ra))
    nobs = n_elements(mt.jd)
    nobj = n_elements(mt.ra)
endelse

close_match_radec,ra,dec,mt.ra[allobj],mt.dec[allobj],m1,m2,0.0009*matchrad,1,/silent

if (m2[0] ne -1) then begin
    ra = mt.ra[m2]
    dec = mt.dec[m2]
endif
mtparts = str_sep(mtname,'_')
rabits = sixty(ra/15.)
decbits = sixty(abs(dec))
sign = '+'
if (dec lt 0.0) then sign = '-'
fname_base = name + '_' + string(rabits[0],format='(i2.2)') + $
             string(rabits[1],format='(i2.2)') + $
             string(rabits[2],format='(i2.2)') + sign + $
             string(decbits[0],format='(i2.2)') + $
             string(decbits[1],format='(i2.2)') + $
             string(decbits[2],format='(i2.2)') + '_' + $
             mtparts[1]
;; if there's no match, there's no problem
write_binary,mt,sts,m2,0.0,0.0,0,0.0,conf.workdir + '/' + fname_base + '.bin',fail=fail
if (fail) then begin
    print,'Failed to write binary file.'
endif

mvcmd = "mv " + conf.workdir + '/' + fname_base + '.bin '

;; and for the last part
parts = str_sep(mt.imagename[0],'_')
cnamebase = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,2)

;; and now we need to find the cobj files to create the mosaic
cobjs=['','','','']
for i=0l,3 do begin
    ;; first, look for coadd
    testname = cnamebase + string(i*10+1,format='(i3.3)') + '-' + $
               string(i*10+10,format='(i3.3)') + '_cobj.fit'
    cname = find_rotse3_cobj(testname,fail=fail)
    if (fail) then begin
        j = 1l
        found_cobj = 0
        while (j le 10 and not found_cobj) do begin
            testname = cnamebase + string(i*10+j,format='(i3.3)') + '_cobj.fit'
            cname = find_rotse3_cobj(testname,fail=fail)
            if (not fail) then begin
                found_cobj = 1
                cobjs[i] = cname
            endif
            j=j+1
        endwhile
    endif else begin
        cobjs[i] = cname
    endelse

    ;; now, make the mosaic
    jpegname = fname_base + '_' + string(i,format='(i1)') + '.jpg'
    fulljpeg = conf.workdir + '/' + jpegname
    if cobjs[i] ne '' then begin
        cal=mrdfits(cobjs[i],2)
        radec_circle_new,cal,ra,dec,/finding,jpegname=fulljpeg,radius=10,dim=[400,400], $
                         box=0.1,/putfname
    endif else begin
        ;; put something to indicate no file was available.
        query_no_jpeg,i*10+1,i*10+10,fulljpeg
    endelse

    mvcmd = mvcmd + ' ' + fulljpeg + ' '
endfor

;; finally, mv them into the proper directory
mvcmd = mvcmd + ' ' + conf.bindir
spawn,mvcmd
cmd = "touch " + conf.thumbfile
spawn,cmd

return
end
