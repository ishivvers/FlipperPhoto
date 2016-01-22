pro cobj_to_tp,listfile,outname,ptgstr,xcenter=xcenter,ycenter=ycenter,mjdrange=mjdrange,offset_cut=offset_cut,noplot=noplot

if n_params() eq 0 then begin
    print,'syntax - cobj_to_tp,listfile,outname,ptgstr,xcenter=xcenter,ycenter=ycenter,mjdrange=mjdrange,offset_cut=offset_cut,noplot=noplot'
    return
endif

if n_elements(mjdrange) eq 0 then begin
    mjdrange=[0.0,100000000.]
endif

g=180d/!dpi

openr,lun,listfile,/get_lun
n=1
name=''

openw,lunw,outname,/get_lun

elt = create_struct("mountra",0d,"mountdec",0d,"rac",0d,"decc",0d,"offset",0d,"mjd",0d)

while not eof(lun) do begin
    readf,lun,name,format='(a200)'
    info = str_sep(name," ")
    name = info(0)
    
    print,'Processing file: ',name,' Number:',n

    if n_elements(xcenter) eq 0 then begin
        if (strpos('_3a',name) ne -1) then begin
            xcenter = 1022
        endif else begin  ;; other cameras
            xcenter = 1074
        endelse
        print,'xcenter = ', xcenter
    endif
    if n_elements(ycenter) eq 0 then begin
        if (strpos('_3a',name) ne -1) then begin
            ycenter = 1024
        endif else begin ;; other cameras
            ycenter = 1026
        endelse
        print,'ycenter = ', ycenter
    endif


    cal=mrdfits(name,2)

    if (cal.mjd gt mjdrange[0]) and (cal.mjd lt mjdrange[1]) then begin

        encra = cal.encra
        encdec = cal.encdec
        
        rac = cal.rac
        decc = cal.decc

        if (n eq 1) then begin
                                ; first guy...start off the tpoint file
            printf,lunw,'ROTSE-III Prototype'
            printf,lunw,':EQUAT'
            printf,lunw,':NODA'
            printf,lunw,':ALLSKY'
            printf,lunw,dub_to_str(cal.latitude)
            printf,lunw,''
        endif

                                ; put the rest in...    
        ct2lst,lst,cal.longitud,dummy,cal.mjd+2400000.5
        lst_hr = fix(lst)
        lst_min = (lst-lst_hr)*60.
        lst_str = string(lst_hr,format='(i2)')+' '+string(lst_min,format='(f5.2)')
        line = dub_to_str(cal.rac/15.)+' '+dub_to_str(cal.decc)+' '+ $
          dub_to_str(cal.encra/15.)+' '+dub_to_str(cal.encdec)+' '+lst_str
                
        elt.mountra = cal.mountra
        elt.mountdec = cal.mountdec
        elt.rac = rac
        elt.decc = decc
        elt.mjd = cal.mjd
        
        gcirc,0,elt.mountra/g,elt.mountdec/g,elt.rac/g,elt.decc/g,dis
        elt.offset = dis * g

        add_arrval,elt,ptg

        if (n_elements(offset_cut) gt 0) then begin
            if (elt.offset le offset_cut) then begin
                printf,lunw,line
            endif else begin
                print,'Offset too large:',elt.offset
            endelse
        endif else begin
            printf,lunw,line
        endelse

        n=n+1
    endif
endwhile

free_lun,lun
free_lun,lunw

ptgstr = ptg

if not keyword_set(noplot) then begin
	plot,ptg.mjd-min(ptg.mjd),ptg.offset,psym=1
endif

return
end
