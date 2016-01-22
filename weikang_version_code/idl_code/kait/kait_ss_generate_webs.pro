pro kait_ss_generate_webs,fieldname,workdir=workdir

if n_params() eq 0 then begin
    print,'kait_ss_generate_webs,fieldname'
    return
endif

respdir='/kait/web/response/'
if not keyword_set(workdir) then workdir='./'

refdir='/kait/ref_cal/'
refwcsfile=refdir+fieldname+'_cwcs.fit'


cd,workdir

templateimagename=fieldname+'.fit'
print,templateimagename
newimagename=fieldname+'_001.fit'
subimagename=fieldname+'_001.sub.fit'
;readin the image fit files
refim=readfits(templateimagename,refhdr)
newim=readfits(newimagename,newhdr)
subim=mrdfits(subimagename,/silent)

;get date time information
date=sxpar(newhdr,'DATE-OBS')
uttime=sxpar(newhdr,'UT')
day1=strmid(date,0,2)
month1=strmid(date,3,2)
year1=strmid(date,6,4)
hour1=strmid(uttime,0,2)
minute1=strmid(uttime,3,2)
second1=strmid(uttime,6,2)
day2=day1
month2=month1
year2=year1
hour2=hour1
minute2=minute1
second2=second1
date=sxpar(refhdr,'DATE-OBS')
uttime=sxpar(refhdr,'UT')
dayr=strmid(date,0,2)
monthr=strmid(date,3,2)
yearr=strmid(date,6,4)
hourr=strmid(uttime,0,2)
minuter=strmid(uttime,3,2)
secondr=strmid(uttime,6,2)

jpegnamebase=strmid(year1,2,2)+month1+day1+'_ss_'+fieldname+'_kait'
;print,jpegnamebase

jpegnamenew=jpegnamebase+'_new.jpg'
jpegnameref=jpegnamebase+'_ref.jpg'
jpegnamesub=jpegnamebase+'_sub.jpg'
candname=jpegnamebase+'.bin'

candinnewimagename=fieldname+'.z.can'
candintemplateimagename=fieldname+'.z.cans'

f=findfile(fieldname+'.mp.cor')
mps=[]
if f[0] ne '' then begin
  readcol,f[0],mpx,mpy,mpmag,format='(f,f,f)'
  for i=0,n_elements(mpx)-1 do begin
    mps=[[mpx[i],mpy[i],mpmag[i]],[mps]]
  endfor
endif


candinnewimage_x=float(readdataarr(candinnewimagename,1))
candinnewimage_y=float(readdataarr(candinnewimagename,2))
candintemplateimage_x=float(readdataarr(candintemplateimagename,1))
candintemplateimage_y=float(readdataarr(candintemplateimagename,2))

;make full frame jpg image
plotdim=[500,500]
ss_regions_to_jpeg,subim,jpegname=jpegnamesub,quality=70,dim=plotdim,xim=candintemplateimage_x-1,yim=candintemplateimage_y-1,box=30,color='green',/nonumber
ss_regions_to_jpeg,newim,jpegname=jpegnamenew,quality=70,dim=plotdim,xim=candinnewimage_x-1,yim=candinnewimage_y-1,box=30,color='green',/nonumber
ss_regions_to_jpeg,refim,jpegname=jpegnameref,quality=75,dim=plotdim,xim=candintemplateimage_x-1,yim=candintemplateimage_y-1,box=30,color='green'

;make sub image for each candidate

;For current, ra dec are actually x y, will updated it when got wcs information for kait image
ra=candintemplateimage_x*360.0/500.0
dec=candintemplateimage_y*180.0/500.0-90.0
;Try to find the real ra,dec
wcsf=findfile(refwcsfile)
if wcsf ne '' then begin
  h=headfits(wcsf[0])
  extast,h,astr
  ;;;## -1.0 is added on 130422 to accound difference in IDL and IRAF
  xy2ad,candintemplateimage_x-1.0,candintemplateimage_y-1.0,astr,realra,realdec
  ra=realra
  dec=realdec
endif

nfind=n_elements(candintemplateimage_x)
rastring=strarr(nfind)
decstring=strarr(nfind)
for ij=0,nfind-1 do begin
  jpegname=strarr(3)

  rastrgs=string(round(sixty(ra[ij]/15d0)),format='(i2)')
  rastrgs=repstr(rastrgs,' ','0')
  decstrgs=string(round(sixty(abs(dec[ij]))),format='(i2)')
  decstrgs=repstr(decstrgs,' ','0')
  rastring[ij]=rastrgs[0]+rastrgs[1]+rastrgs[2]
  decstring[ij]=decstrgs[0]+decstrgs[1]+decstrgs[2]
  if dec[ij] lt 0 then decstring[ij]='-'+decstring[ij] else decstring[ij]='+'+decstring[ij]

  targetid=jpegnamebase+'_'+rastring[ij]+decstring[ij]
  jpegname[0]=targetid+'_new.jpg'
  jpegname[1]=targetid+'_ref.jpg'
  jpegname[2]=targetid+'_sub.jpg'

  caption='New image '+'x='+string(candinnewimage_x[ij],format='(f5.1)')+' y='+string(candinnewimage_y[ij],format='(f5.1)')
  plot_kait_subimage,newim,candinnewimage_x[ij],candinnewimage_y[ij],/nolabel,jpegname=jpegname[0],caption=caption,mps=mps
  caption='Ref image '+'x='+string(candintemplateimage_x[ij],format='(f5.1)')+' y='+string(candintemplateimage_y[ij],format='(f5.1)')
  plot_kait_subimage,refim,candintemplateimage_x[ij],candintemplateimage_y[ij],/nolabel,jpegname=jpegname[1],caption=caption
  plot_kait_subimage,subim,candintemplateimage_x[ij],candintemplateimage_y[ij],/nolabel,jpegname=jpegname[2],caption='Sub image'
endfor

;save the candidates list as a binary file
new1time=string(month1,format='(i02)')+'.'+string(day1,format='(i02)')+'.'+string(year1,format='(i4)')+' '+string(hour1,format='(i02)')+':'+string(minute1,format='(i02)')+':'+string(second1,format='(i02)')
new2time=string(month2,format='(i02)')+'.'+string(day2,format='(i02)')+'.'+string(year2,format='(i4)')+' '+string(hour2,format='(i02)')+':'+string(minute2,format='(i02)')+':'+string(second2,format='(i02)')
reftime=string(monthr,format='(i02)')+'.'+string(dayr,format='(i02)')+'.'+string(yearr,format='(i4)')+' '+string(hourr,format='(i02)')+':'+string(minuter,format='(i02)')+':'+string(secondr,format='(i02)')

openw,unit,candname,/get_lun
writeu,unit,new1time,new2time,reftime
writeu,unit,long(nfind)
for i=0,nfind-1 do begin
    ;now, here to check the history log
    inputinfo={ra:double(ra[i]), dec:double(dec[i]), epoch:double(2000), year: year1, month:month1, day:day1, hour:hour1, monute:minute1, second:second1, totaltimes:1.0, detectedtimes:1.0}
    ;print,inputinfo
    kait_ss_check_history_log,fieldname,inputinfo,outputinfo
    ;print,outputinfo
    if outputinfo.ra eq inputinfo.ra and outputinfo.dec eq inputinfo.dec then begin
    ;if outputinfo.totaltimes le 1 then begin
      noldstr=string(0,format='(i02)')+'/'+string(0,format='(i02)')+'/'+'0000'
    endif else begin
      noldstr=string(outputinfo.totaltimes,format='(i02)')+'/'+string(outputinfo.detectedtimes,format='(i02)')+'/'+outputinfo.month+outputinfo.day
    endelse
    writeu,unit,double(ra[i]),double(dec[i])
    writeu,unit,rastring[i],decstring[i]
    writeu,unit,float(0.0)
    writeu,unit,long(0)
    writeu,unit,long(0)
    writeu,unit,float(0),long(0),float(candintemplateimage_x[i]-1),float(candintemplateimage_y[i]-1),float(0),float(0)
    writeu,unit,noldstr
    ;writeu,unit,double(sobj0[i].ra),double(sobj0[i].dec)
    ;writeu,unit,rastring[i],decstring[i]
    ;writeu,unit,float(sobj0[i].mag_aper)
    ;writeu,unit,long(sobj0[i].mcase)
    ;writeu,unit,long(sobj0[i].percent)
    ;writeu,unit,float(sobj0[i].snr),long(sobj0[i].isoarea_image),float(sobj0[i].x_image-1),float(sobj0[i].y_image-1),float(sobj0[i].fwhm_image),float(sobj0[i].motion)
    ;writeu,unit,noldstr[i]
endfor
close,unit
free_lun,unit

;put the plots into the respdir

cmd = "chmod 666 " + jpegnamebase+'*.jpg'
spawn,cmd
cmd = "cp "+jpegnamebase+'*.jpg'+" "+respdir
spawn,cmd
cmd = "rm -f "+jpegnamebase+'*.jpg'
spawn,cmd
cmd = "chmod 666 " + candname
spawn,cmd
cmd = "cp "+candname+" "+respdir
spawn,cmd
cmd = "rm -f "+candname
spawn,cmd

end
