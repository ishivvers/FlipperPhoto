; ********************************************************************************
pro rphot_assert_select,event
COMPILE_OPT IDL2

;; change the mode to "select"

widget_control,event.top,get_uvalue=data
(*data).mode='select'

end

; ********************************************************************************
pro rphot_select_all_stars,event
COMPILE_OPT IDL2

widget_control,event.top,get_uvalue=data
refims=(*(*data).images)[(*data).refi]

;; assign the refstars
rphot_get_aper_counts,data,*refims.objx,*refims.objy,flux,eflux

nstars=n_elements(*refims.objx)
blank1=dblarr(nstars)-1
blank2=dblarr(nstars)+!values.d_nan

*refims.refx=transpose([[*refims.objx],[blank1]])
*refims.refy=transpose([[*refims.objy],[blank1]])
*refims.refcounts=transpose([[flux],[blank2]])
*refims.refecounts=transpose([[eflux],[blank2]])
*refims.refra=*refims.objra
*refims.refdec=*refims.objdec

(*(*data).images)[(*data).refi]=refims
rphot_display_image,data

end


; ********************************************************************************
pro rphot_auto_select_refstars,event
COMPILE_OPT IDL2

;; automatically selects all objects (even ugly saturated ones) within
;; the specified radius.

widget_control,event.top,get_uvalue=data
refims=(*(*data).images)[(*data).refi]

widget_control,(*data).select_radius_id,get_value=radius
radius=radius[0]/60.0d ; radius in deg
prad=radius*3600.0/3.28 ; convert to pixels

widget_control,(*data).select_minsn_id,get_value=minsn
minsn=minsn[0]

;; get all objects within radius
close_match_radec,*refims.objra,*refims.objdec,refims.ra,refims.dec,wref,junk,radius,1.0,missed

;; keep the well seperated objects
minsep=2.0*(*data).fixrad
keep=intarr(n_elements(*refims.objra))
n=n_elements(wref)
for i=0,n-1 do begin
    x=(*refims.objx)[wref[i]]
    y=(*refims.objy)[wref[i]]
    dist=sqrt((*refims.objx-x)^2.0 + (*refims.objy-y)^2.0)
    dist=dist[where(dist gt 0)]
    if min(dist) gt minsep then keep[wref[i]]=1

    ;; make sure its not the target
    dist=sqrt((refims.x[0]-x)^2.0 + (refims.y[0]-y)^2.0)
    if dist lt minsep then keep[wref[i]]=0
endfor

if keyword_set(debug) then begin
    col=getcolor(/load)
    rphot_display_image,data
    w=where(keep eq 0,nw)
    if nw gt 0 then boxdata,6,(*refims.objx)[w],(*refims.objy)[w],color=col.red
endif

w=where(keep eq 1 and sqrt(((*refims.objx)-refims.x[0])^2.0 + ((*refims.objy)-refims.y[0])^2.0) gt minsep, nw)
if nw gt 0 then begin
    ;; assign the refstars
    x=(*refims.objx)[w]
    y=(*refims.objy)[w]
    flags=(*refims.flags)[w]
    edgerad=2.0*( (*data).fixrad > refims.fwhm )
    rphot_get_aper_counts,data,x,y,flux,eflux

    if keyword_set(debug) then begin
        ;; show cuts
        wbad=where(flags ne 0,nbad)
        if nbad gt 0 then boxdata,8,x[wbad],y[wbad],color=col.orange
        wbad=where(flux/eflux le minsn,nbad)
        if nbad gt 0 then boxdata,10,x[wbad],y[wbad],color=col.green
        wbad=where(flux ge 0.75*refims.satflux,nbad)
        if nbad gt 0 then boxdata,12,x[wbad],y[wbad],color=col.blue
    endif

    ;; cut out faint/saturated refstars
    w2=where(flags eq 0 and flux/eflux gt minsn and flux lt 0.75*refims.satflux $
             and x gt edgerad and y gt edgerad and x lt refims.nx-edgerad and y lt refims.ny-edgerad,nw2)

    if nw2 le 0 then w2=indgen(n_elements(flux))
    blank1=dblarr(n_elements(w2))-1
    blank2=dblarr(n_elements(w2))+!values.d_nan
    *refims.refx=transpose([[x[w2]],[blank1]])
    *refims.refy=transpose([[y[w2]],[blank1]])
    *refims.refra=((*refims.objra)[w])[w2]
    *refims.refdec=((*refims.objdec)[w])[w2]
    *refims.refcounts=transpose([[flux[w2]],[blank2]])
    *refims.refecounts=transpose([[eflux[w2]],[blank2]])

    (*(*data).images)[(*data).refi]=refims
    rphot_display_image,data
endif

end

; ********************************************************************************
pro rphot_rd_string_to_xy,event
COMPILE_OPT IDL2

;; get the ra and dec from user input, and convert it to an xy
;; location.

widget_control,event.top,get_uvalue=data

widget_control,(*data).ra_id,get_value=inra
widget_control,(*data).dec_id,get_value=indec

;; see if the values are both decimal degrees
worked=0
got_dra=stregex(inra,'[^0-9.+-]+',/extract)
got_ddec=stregex(indec,'[^0-9.+-]+',/extract)
if got_dra[0] eq '' and got_ddec[0] eq '' then begin
    dra=double(inra)
    ddec=double(indec)
    worked=1
endif else begin
    ;; see if the values are both sexigesimal 
    ra=stregex(inra,'([-+]*)([0-9]+):([0-9]+):([0-9.]+)',/subexpr,/extract)
    dec=stregex(indec,'([-+]*)([0-9]+):([0-9]+):([0-9.]+)',/subexpr,/extract)
    if ra[0] ne '' and dec[0] ne '' then begin
        dra=15.0*(ra[2]+ra[3]/60.0+ra[4]/3600.0)
        ddec=dec[2]+dec[3]/60.0+dec[4]/3600.0
        if dec[1] eq '-' then ddec=-ddec
        worked=1
    endif
endelse

if worked eq 1 then begin
    ;; convert ra/dec values to x,y position on refimage
    ;;rphot_rd2xy,(*(*data).images)[(*data).refi].cobjfile,dra,ddec,x,y
    refims=(*(*data).images)[(*data).refi]
    rphot_rd2xy,refims.crval,*refims.rdkx,*refims.rdky,dra,ddec,x,y

    (*(*data).images)[(*data).refi].x=x
    (*(*data).images)[(*data).refi].y=y
    (*(*data).images)[(*data).refi].ra=dra
    (*(*data).images)[(*data).refi].dec=ddec
    (*data).current_image=(*data).refi
    rphot_display_image,data
    rphot_display_closeup,data
endif else begin
    ;; failure 
    print,'RPHOT: Error; Bad RA/DEC value'
endelse

end


;; ********************************************************************************
;; ********************************************************************************
pro rphot_select_objects,data,ims,just_one=just_one
COMPILE_OPT IDL2

;; this is a widget to allow users to select targets and refstars
;; either by clicking on the image, or by entering RA and DEC values.

if keyword_set(just_one) then (*data).just_one=just_one else (*data).just_one=0

;; *** this is the top level widget ***
base=widget_base(column=1,/base_align_center,title='RPHOT: Select Objects')

label=widget_label(base,value='Enter RA, DEC:')
ra_id=cw_field(base,uvalue='ra',xsize=12,ysize=1,title='RA',value='21:49:24.40')
dec_id=cw_field(base,uvalue='dec',xsize=12,ysize=1,title='DEC',value='-27:42:47.4')
but=widget_button(base,value='Show',event_pro='rphot_rd_string_to_xy')
(*data).ra_id=ra_id
(*data).dec_id=dec_id

label=widget_label(base,value='OR')
blah=widget_base(base,row=1,/base_align_center)
;;but=widget_button(blah,value='Zoom...',event_pro='zoom_image')
label=widget_label(blah,value='Zoom then')
but=widget_button(base,value='Select by Cursor',event_pro='rphot_assert_select')

if (*data).just_one eq 0 then begin
    label=widget_label(base,value='OR')
    radius=cw_field(base,uvalue='radius',xsize=4,ysize=1,title='Radius (arcmin)',value='10')
    (*data).select_radius_id=radius
    minsn=cw_field(base,uvalue='minsn',xsize=4,ysize=1,title='Minimum S/N',value='10')
    (*data).select_minsn_id=minsn
    but=widget_button(base,value='Auto Select',event_pro='rphot_auto_select_refstars')
    but=widget_button(base,value='Select All',event_pro='rphot_select_all_stars')
endif

botbase=widget_base(base,row=1,/base_align_right)
but=widget_button(botbase,value='Done',event_pro='rphot_done',frame=3,uvalue='select_objects')
;;but=widget_button(botbase,value='Cancel',event_pro='rphot_done',frame=3,uvalue='cancel_select')

widget_control,base,set_uvalue=data
widget_control,base,group_leader=(*data).main_id
(*data).select_objects_id=base

;; show everything
widget_control,base,/realize
xmanager,'select_objects',base,/no_block

end

