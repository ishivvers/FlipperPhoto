pro zphot_get_photometry_allstars,data,phasedata=phasedata,outst=outst
COMPILE_OPT IDL2

 if N_params() eq 0 then begin
        print,'Syntax: rphot_get_photometry_allstars,data,phasedata=phasedata,outst=outst'
        return
 endif

;; which photometry system are we using?
psys=1

;; time in mjd
x=(*(*data).images).mjd
ex=(*(*data).images).mjd+(*(*data).images).efftime/3600./24.
cobjfiles=(*(*data).IMAGES).COBJFILE
sites=strarr(n_elements(cobjfiles))
for i=0,n_elements(cobjfiles)-1 do begin
  nameparts=strsplit(((*(*data).IMAGES).COBJFILE)[i],'_',/extract)
  sites[i]=strmid(nameparts[2],0,2)
endfor
temp=sites[sort(sites)]
scopes=temp[uniq(temp)]

zp=(*data).zp[psys]

;; get the relative flux in each aper
rphot_get_relative_flux,data,fluxes,efluxes,/allobjects,psys=psys

mags=-2.5*alog10(fluxes)+zp
emags=(2.5/alog(10))*(efluxes/fluxes)

index=sort(x)
x=x[index]
ex=ex[index]
mags=mags[0,index,*]
emags=emags[0,index,*]
cobjfiles=cobjfiles[index]

x0=min(x)
scopesnumber=n_elements(scopes)
starsnumber=n_elements(mags[0,0,*])
imagesnumber=n_elements(x)
goodstars=strarr(scopesnumber,starsnumber)
goodstars_count=lonarr(scopesnumber)

;; not done, because we need to group different telescope first.
;meanmags=dblarr(starsnumber)
;sigmastars=dblarr(starsnumber)
;for j=0L,starsnumber-1 do begin
;  index=where(mags[0,index,*] gt 1,nfind)
;  if (nfind gt 0) then begin
;    result=moment(mags[0,index,*]
;    meanmags[j]=result[0]
;    sigmastars[j]=result[1]
;  endif else begin
;    meanmags[j]=0.0
;    sigmastars[j]=99.0
;  endelse
;endfor

refims=(*(*data).images)[(*data).refi]
starsnumber=(*data).allstarsbumber
outphotst={refims:'', images:strarr(imagesnumber), id:strarr(starsnumber), ra:dblarr(starsnumber), dec:dblarr(starsnumber), mjd:dblarr(imagesnumber), mags:dblarr(imagesnumber,starsnumber), emags:dblarr(imagesnumber,starsnumber)}
;starsnumber=n_elements(mags[0,0,*])-10;-n_elements((*refims.refx)[0,*])
outphotst.refims=refims.COBJFILE
outphotst.images=cobjfiles
outphotst.ra=(*refims.objra)[0:starsnumber-1]
outphotst.dec=(*refims.objdec)[0:starsnumber-1]
outphotst.mjd=x
outphotst.mags=reform(mags[0,*,0:starsnumber-1])
outphotst.emags=reform(emags[0,*,0:starsnumber-1])
for i=0L,starsnumber-1 do begin
  outphotst.id[i]=string(i+1,format='(i04)')
endfor
outst=outphotst
;for i=0L,imagesnumber-1 do begin
;  outstr=string(x[i],mags[0,i,0],emags[0,i,0],format='(a,a,a)')
;  for j=1L,starsnumber-1 do begin
;    outstr=string(outstr,mags[0,i,j],emags[0,i,j],format='(a,a)')
;  endfor
;  print,outstr
;endfor

if keyword_set(phasedata) then begin

  for j=0L,starsnumber-1 do begin
    outname1_base=strarr(scopesnumber)
    for k=0,scopesnumber-1 do begin
      outname1_base[k]=string((*data).name,'_Pdata_',j+1,'_',scopes[k],format='(a,a,i04,a,a)')
      outname1=outname1_base+'.dat'
    endfor
    outname2=string((*data).name,'_Adata_',j+1,'.dat',format='(a,a,i04,a)')
    openw,out_All,outname2,/get_lun
    for k=0,scopesnumber-1 do begin
      case scopes[k] of
        '3a': begin
                openw,out_Panalysis3a,outname1[k],/get_lun
                printf,out_Panalysis3a,''
                printf,out_Panalysis3a,''
                printf,out_Panalysis3a,''
                printf,out_Panalysis3a,''
              end
        '3b': begin
                openw,out_Panalysis3b,outname1[k],/get_lun
                printf,out_Panalysis3b,''
                printf,out_Panalysis3b,''
                printf,out_Panalysis3b,''
                printf,out_Panalysis3b,''
              end
        '3c': begin
                openw,out_Panalysis3c,outname1[k],/get_lun
                printf,out_Panalysis3c,''
                printf,out_Panalysis3c,''
                printf,out_Panalysis3c,''
                printf,out_Panalysis3c,''
              end
        '3d': begin
                openw,out_Panalysis3d,outname1[k],/get_lun
                printf,out_Panalysis3d,''
                printf,out_Panalysis3d,''
                printf,out_Panalysis3d,''
                printf,out_Panalysis3d,''
              end
      endcase
    endfor
    gooddata=lonarr(scopesnumber)
    for i=0L,imagesnumber-1 do begin
      if (Finite(mags[0,i,j]) ne 0 and emags[0,i,j] le 0.3) then begin
        case sites[i] of
        '3a': begin
                printf,out_Panalysis3a,x[i]-x0,mags[0,i,j],emags[0,i,j]
                index=where(sites[i] eq scopes)
                gooddata[index]=gooddata[index]+1
              end
        '3b': begin
                printf,out_Panalysis3b,x[i]-x0,mags[0,i,j],emags[0,i,j]
                index=where(sites[i] eq scopes)
                gooddata[index]=gooddata[index]+1
              end
        '3c': begin
                printf,out_Panalysis3c,x[i]-x0,mags[0,i,j],emags[0,i,j]
                index=where(sites[i] eq scopes)
                gooddata[index]=gooddata[index]+1
              end
        '3d': begin
                printf,out_Panalysis3d,x[i]-x0,mags[0,i,j],emags[0,i,j]
                index=where(sites[i] eq scopes)
                gooddata[index]=gooddata[index]+1
              end
        endcase
      endif
      printf,out_All,x[i],mags[0,i,j],emags[0,i,j],' ',cobjfiles[i],format='(a,a,a,a,a)'
    endfor
  
    for k=0,scopesnumber-1 do begin
      case scopes[k] of
        '3a': begin
                close,out_Panalysis3a
                free_lun,out_Panalysis3a
              end
        '3b': begin
                close,out_Panalysis3b
                free_lun,out_Panalysis3b
              end
        '3c': begin
                close,out_Panalysis3c
                free_lun,out_Panalysis3c
              end
        '3d': begin
                close,out_Panalysis3d
                free_lun,out_Panalysis3d
              end
       endcase
    endfor
    close,out_All
    free_lun,out_All
  
    for k=0,scopesnumber-1 do begin
      if (gooddata[k] le 10) then begin
        cmd="rm -f "+outname1[k]
        spawn,cmd
      endif else begin
        goodstars[k,goodstars_count]=outname1_base[k]
        goodstars_count[k]=goodstars_count[k]+1
      endelse
    endfor
  endfor
  
  idlshname=strarr(scopesnumber)
  for k=0,scopesnumber-1 do begin
    idlshname[k]=string('idlshP_',(*data).name,'_',scopes[k],format='(a,a,a,a)')
  endfor
  for k=0,scopesnumber-1 do begin
    case scopes[k] of
      '3a': begin
              openw,idlsh3a,idlshname[k],/get_lun
            end
      '3b': begin
              openw,idlsh3b,idlshname[k],/get_lun
            end
      '3c': begin
              openw,idlsh3c,idlshname[k],/get_lun
            end
      '3d': begin
              openw,idlsh3d,idlshname[k],/get_lun
            end
    endcase
    for i=0L,goodstars_count[k]-1 do begin
      case scopes[k] of
      '3a': begin
              printf,idlsh3a,'single_phase,',"'",goodstars[k,i],"'"
              printf,idlsh3a,'retall'
              printf,idlsh3a,'plot_datfile,',"'",goodstars[k,i],"'",',post=',"'",goodstars[k,i],'.ps',"'"
              printf,idlsh3a,'retall'
              printf,idlsh3a,"$convert ",goodstars[k,i],".ps  ",goodstars[k,i],".png"
              printf,idlsh3a,'retall'
            end
      '3b': begin
              printf,idlsh3b,'single_phase,',"'",goodstars[k,i],"'"
              printf,idlsh3b,'retall'
              printf,idlsh3b,'plot_datfile,',"'",goodstars[k,i],"'",',post=',"'",goodstars[k,i],'.ps',"'"
              printf,idlsh3b,'retall'
              printf,idlsh3b,"$convert ",goodstars[k,i],".ps  ",goodstars[k,i],".png"
              printf,idlsh3b,'retall'
            end
      '3c': begin
              printf,idlsh3c,'single_phase,',"'",goodstars[k,i],"'"
              printf,idlsh3c,'retall'
              printf,idlsh3c,'plot_datfile,',"'",goodstars[k,i],"'",',post=',"'",goodstars[k,i],'.ps',"'"
              printf,idlsh3c,'retall'
              printf,idlsh3c,"$convert ",goodstars[k,i],".ps  ",goodstars[k,i],".png"
              printf,idlsh3c,'retall'
            end
      '3d': begin
              printf,idlsh3d,'single_phase,',"'",goodstars[k,i],"'"
              printf,idlsh3d,'retall'
              printf,idlsh3d,'plot_datfile,',"'",goodstars[k,i],"'",',post=',"'",goodstars[k,i],'.ps',"'"
              printf,idlsh3d,'retall'
              printf,idlsh3d,"$convert ",goodstars[k,i],".ps  ",goodstars[k,i],".png"
              printf,idlsh3d,'retall'
            end
      endcase
    endfor
  
    case scopes[k] of
      '3a': begin
              close,idlsh3a
              free_lun,idlsh3a
              cmd="cp -f "+idlshname[k]+" "+idlshname[k]+".bak"
              spawn,cmd
            end
      '3b': begin
              close,idlsh3b
              free_lun,idlsh3b
              cmd="cp -f "+idlshname[k]+" "+idlshname[k]+".bak"
              spawn,cmd
            end
      '3c': begin
              close,idlsh3c
              free_lun,idlsh3c
              cmd="cp -f "+idlshname[k]+" "+idlshname[k]+".bak"
              spawn,cmd
            end
      '3d': begin
              close,idlsh3d
              free_lun,idlsh3d
              cmd="cp -f "+idlshname[k]+" "+idlshname[k]+".bak"
              spawn,cmd
            end
    endcase
  endfor
endif
end
