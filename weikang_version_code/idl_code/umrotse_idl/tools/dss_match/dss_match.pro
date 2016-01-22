pro dss_match,mt,st,ra,dec,err,imname=imname,obs=obs,dss_name=dss_name,tilesize=tilesize,ngood=ngood,obj_arr=obj_arr
;+
; NAME: dss_match
;
; CALLING_SEQUENCE:  dss_match,mt,st,ra,dec,err
;
; INPUTS:   mt: match structure
;           st: stats structure (match fits 2nd extension)
;           ra, dec: center of error box
;           err: radius of error box
;
; KEYWORDS: imname: name of image to display OR
;           obs: observation number in match structure
;    NOTE: one of the previous two keywords must be set
;           dss_name: name of dss image (otherwise computer generated)
;           tilesize: scanning tile size
;           ngood: min obs in structure for object to be circled (=5)
;
; OUTPUTS:  obj_arr: array of saved objects
;
; PROCEDURE: This tool compares one image from a match structure to the DSS 2nd
; generation R-band survey (downloaded from the web).  All objects that are not
; in the USNO-B catalog (also downloaded) are circled and labeled for easy
; comparison.  Interesting objects can be saved and their light curves plotted
; in a separate window.
;
; Created: 01-16-04 Eli Rykoff
;
;-


if n_params() eq 0 then begin
    print,'syntax- dss_match,mt,st,ra,dec,err,imname=imname,obs=obs,dss_name=dss_name,tilesize=tilesize,ngood=ngood,obj_arr=obj_arr'
    return
endif

if n_elements(tilesize) eq 0 then tilesize = 0.1
if (err gt 0.33) then begin
    print,'Only works up to 40 arcminutes across (err <= 0.33)'
    return
endif
    
if (n_elements(imname) eq 0) and (n_elements(obs) eq 0) then begin
    print,'must specify an image name or an observation'
    return
endif

if (n_elements(imname) gt 0) and (n_elements(obs) gt 0) then begin
    print,'must only specify one of image name or observation'
    return
endif

if n_elements(ngood) eq 0 then begin 
    ngood = 5
endif

print,'Ngood set to ',ngood


if (n_elements(obs) gt 0) then begin
    imname = mt.imagename[obs[0]]
endif

obj_arr=-1

dirsep=strsplit(imname,'/',/extract)
parts=strsplit(dirsep[n_elements(dirsep)-1],'_',/extract)
date = parts[0]

if n_elements(parts) eq 3 then begin
    fbase = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,5)
endif else begin
    fbase = parts[0] + '_' + parts[1] + '_' + parts[2]
endelse

imname = fbase + '_c.fit'
cobjname=fbase + '_cobj.fit'

if n_elements(dss_name) eq 0 then begin
    ;; generate dss_name
    dss_name=generate_rotse3_fname(date,'dss',ra,dec,'x')
endif

;; try to find the dss image if it's already been downloaded
full_dss_name = find_rotse3_image(dss_name,path=['.','image'],fail=fail)

if (fail eq 1) then begin
    ;; we need to download it
    print,'Downloading DSS image...'
    querydss,[ra,dec],dss_image,dss_hdr,imsize=fix(2.*err*60.),survey='2r'
    
    ;; now, we need to save it (where?)
    ;; check if an 'image' subdirectory exists
    test=findfile('image/',count=ct)
    if (ct gt 0) then begin
        full_dss_name = 'image/' + dss_name + '_c.fit'
    endif else begin
        print,'There does not appear to be an image subdirectory.  Saving in current directory'
        full_dss_name = dss_name + '_c.fit'
    endelse
    print,'Saving DSS image as '+full_dss_name
    writefits,full_dss_name,dss_image,dss_hdr

endif else begin
    print,'Reading DSS image...'
    dss_image = readfits(full_dss_name,dss_hdr)
endelse

dss_hdr=dss_hdr[0:100]


;; now find the image
full_image_name = find_rotse3_image(imname,path=['.','image'],fail=fail)
if (fail eq 1) then begin
    print,'Could not find image: '+imname
    return
endif
im=readfits(full_image_name,im_hdr)

;; and the cobj file if necessary
if (n_elements(obs) gt 0) then begin
    cal = reform(st[obs])
endif else begin
    full_cobj_name = find_rotse3_cobj(cobjname,path=['.','prod'],fail=fail)
    if (fail eq 1) then begin
        print,'Could not find cobj: '+cobjname
        return
    endif
    cobj=mrdfits(full_cobj_name,1)
    cal=mrdfits(full_cobj_name,2)
endelse

gdobj=where(mt.ngood ge ngood)

;; now get the tiling ready
 decliml=dec-err
 declimh=dec+err
 raliml=ra-(err/cos(dec*0.01745))
 ralimh=ra+(err/cos(dec*0.01745))

 astr_struct_new,1.85,astr
 astr.crval=[double(cal.rac),double(cal.decc)]
 rd2xy,[raliml,ralimh],[decliml,declimh],astr,xc,yc
 kmap,xc,yc,xx,yy,cal.kx,cal.ky

 tscale = tilesize / astr.cdelt[0]

 nxtiles = ceil((max(xx)-min(xx))/tscale)
 nytiles = ceil((max(yy)-min(yy))/tscale)

 ;; new tscale
 tscale_x = (max(xx)-min(xx))/nxtiles
 tscale_y = (max(yy)-min(yy))/nytiles
 if (tscale_x gt tscale_y) then tscale = tscale_x else tscale = tscale_y

 if nxtiles eq 1 then begin
     xtiles=[(max(xx)+min(xx))/2.]
 endif else begin
     xtiles=(findgen(nxtiles)/(nxtiles-1))*(max(xx)-min(xx)-tscale) + min(xx)+tscale/2.
 endelse
 if nytiles eq 1 then begin
     ytiles=[(max(yy)+min(yy))/2.]
 endif else begin
     ytiles=(findgen(nytiles)/(nytiles-1))*(max(yy)-min(yy)-tscale) + min(yy)+tscale/2.
 endelse
 
 ;; and back to ra/dec space
 xyad,im_hdr,xtiles,ytiles,ratiles,dectiles   ;; really approximate, especially with diagonal
 tilesize = tscale * astr.cdelt[0]


;; read in the entire usnob catalog...will want to check if it's already there
 print,'Reading in USNO B Catalog'
 usnoreadb,ra,dec,err*1.2,ubcat,/save

;; and match the catalog to our stars
 close_match_radec,mt.ra[gdobj],mt.dec[gdobj],ubcat.raj2000,ubcat.dej2000, $
   m1,m2,0.0009d,1,miss


;; now, tile by tile, download, match, and plot

 ppt = 'Type Object Number to Query, or "n/N" for next frame, "q/Q" to quit:'

 for i=0l,n_elements(ratiles)-1 do begin
     for j=0l,n_elements(dectiles)-1 do begin
         this_ra = ratiles[i]
         this_dec = dectiles[j]


         window,0,xsize=1024,ysize=512
         !p.multi=[2,2,0]

         radec_circle_new,cal,this_ra,this_dec,sts=st,image=im,box=tilesize, $
           /finding,radius=5,errad=0, $
           rarr1=mt.ra[gdobj[m1]],darr1=mt.dec[gdobj[m1]], $
           rarr2=mt.ra[gdobj[miss]],darr2=mt.dec[gdobj[miss]],number2=gdobj[miss]

         plot_dss_image,dss_image,dss_hdr,this_ra,this_dec,box=tilesize,radius=10,errad=0, $
           rarr1=mt.ra[gdobj[m1]],darr1=mt.dec[gdobj[m1]], $
           rarr2=mt.ra[gdobj[miss]],darr2=mt.dec[gdobj[miss]], $
           rarr3=ubcat.raj2000,darr3=ubcat.dej2000
         

         nocontinue=1
         while nocontinue do begin
             ans=''
             read,ans,prompt=ppt
             if (ans[0] eq 'n' or ans[0] eq 'N') then begin
                 nocontinue=0
             endif else if (ans[0] eq 'q' or ans[0] eq 'Q') then begin
                 nocontinue=0
                 i=n_elements(ratiles)+1
                 j=n_elements(ratiles)+1
             endif else begin
                 obj=long(ans)
                 if (obj eq 0) then begin
                     print,'Illegal object'
                 endif else if (obj gt n_elements(mt.ra)) then begin
                     print,'Object '+string(obj,format='(i5)')+' not found.'
                 endif else begin

                     print,'Object '+string(obj,format='(i5)') + ':'
                     
                     print,' RA = '+string(mt.ra[obj],format='(f11.7)') + $
                       string(mt.dec[obj],format='(f11.7)')

                     ras=sixty(mt.ra[obj]/15.)
                     decs=sixty(mt.dec[obj])
                     print,' RA = '+string(fix(ras[0]),format='(i2)') + 'h ' + $
                           string(fix(ras[1]),format='(i2)') + 'm ' + $
                           string(ras[2],format='(f5.2)') + 's  Dec = ' + $
                           string(fix(decs[0]),format='(i3)') + 'd ' + $
                           string(fix(decs[1]),format='(i2)') + "' " + $
                           string(decs[2],format='(f5.2)') + '"'

                     print,' ROTSE Mag (mean) = '+string(mt.mavg[obj],format='(f5.2)') + $
                       ' +/- ' + string(mt.mstd[obj],format='(f5.2)')

                     ;; now, we need to find the nearest usno-b object
                     close_match_radec,mt.ra[obj],mt.dec[obj], $
                       ubcat.raj2000,ubcat.dej2000, $
                       mm1,mm2,0.0009d*50d,1,/silent
                     gcirc,1,mt.ra[obj]/15.,mt.dec[obj], $
                       ubcat[mm2].raj2000/15.,ubcat[mm2].dej2000,dis
                     
                     print,''
                     print,'Closest USNO-B object ('+ubcat[mm2].id+') is ' + $
                           string(dis,format='(f5.1)') + '" away:'
                     print,' RA = '+string(ubcat[mm2].raj2000,format='(f11.7)') + $
                           '     Dec = '+string(ubcat[mm2].dej2000,format='(f11.7)')
                         
                     ras=sixty(ubcat[mm2].raj2000/15.)
                     decs=sixty(ubcat[mm2].dej2000)
                     print,' RA = '+string(fix(ras[0]),format='(i2)') + 'h ' + $
                           string(fix(ras[1]),format='(i2)') + 'm ' + $
                           string(ras[2],format='(f5.2)') + 's  Dec = ' + $
                           string(fix(decs[0]),format='(i3)') + 'd ' + $
                           string(fix(decs[1]),format='(i2)') + "' " + $
                           string(decs[2],format='(f5.2)') + '"'

                     print,' R1 = ' + string(ubcat[mm2].r1mag,format='(f5.2)') + $
                           ' R2 = ' + string(ubcat[mm2].r2mag,format='(f5.2)')
                     print,' B1 = ' + string(ubcat[mm2].b1mag,format='(f5.2)') + $
                           ' B2 = ' + string(ubcat[mm2].b2mag,format='(f5.2)')
                     print,' I = ' + string(ubcat[mm2].imag,format='(f5.2)')

                     ans2=''
                     read,ans2,prompt='[s]ave in a list, [p]lot light curve, or nothing?'
                     if (ans2[0] eq 's') or (ans2[0] eq 'S') then begin
                         add_arrval,obj,obj_arr
                     endif else if (ans2[0] eq 'p') or (ans2[0] eq 'P') then begin
                         window,1
                         save_multi=!p.multi
                         !p.multi=0
                         lcplot3,mt,obj,/good,/syserr,/nowait
                         wset,0
                         !p.multi=save_multi
                         ans3=''
                         read,ans3,prompt='Save this? [Y/n]'
                         if ((ans3[0] ne 'n') and (ans3[0] ne 'N')) then begin
                             add_arrval,obj,obj_arr
                         endif                         
                     endif
                 endelse
             endelse
         endwhile
         

     endfor
 endfor

 !p.multi = 0

 h=where(obj_arr ne -1,ct)
 if (ct gt 0) then begin 
     obj_arr=obj_arr[h]
     print,'Objects saved: '
     for i=0l,n_elements(obj_arr)-1 do begin
         print,obj_arr[i]
     endfor
 endif else begin
     print,'No objects saved.'
endelse

return
end
