; ********************************************************************************
pro rphot_image_selected,event
COMPILE_OPT IDL2

;; displays the selected image

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=type

case type of
    'doall': begin
        for i=0,n_elements( (*(*data).images).imname )-1 do begin
            if finite((*(*data).images)[i].counts[0]) eq 0 then begin
                (*data).current_image=i
                widget_control,(*data).imlist_id,set_list_select=(*data).current_image
                rphot_display_image,data
                rphot_display_closeup,data
                rphot_display_plot,data
            endif
        endfor

        return
    end

    'redoall': begin
        ;; wipe all phot data
        ;;rphot_wipe_data,data,/keepref,/keepk

        ;; redo refim
        refims=(*(*data).images)[(*data).refi]
        (*data).current_image=(*data).refi
        rphot_display_image,data
        if refims.fwhm eq 0 then rphot_get_psf,data,refims
        rphot_do_photometry,data

        ;; loop over each image
        for i=0,n_elements( (*(*data).images).imname )-1 do begin
            (*data).current_image=i
            ims=(*(*data).images)[i]
            widget_control,(*data).imlist_id,set_list_select=(*data).current_image

            ;; display
            rphot_display_image,data
            rphot_display_closeup,data

            ;; get the psf
            if ims.fwhm eq 0 then rphot_get_psf,data,ims

            ;; do the photometry
            rphot_do_photometry,data

            rphot_display_plot,data
        endfor

        return
    end

    'previous': (*data).current_image=max([0,(*data).current_image-1])
    'next': (*data).current_image=min([n_elements((*(*data).images).imname)-1,(*data).current_image+1])
    'redraw': 
    else: (*data).current_image=event.index
endcase
widget_control,(*data).imlist_id,set_list_select=(*data).current_image

;; show the image
rphot_display_image,data

;; show the object closeup
rphot_display_closeup,data

;; plot the counts
rphot_display_plot,data

end


;; ********************************************************************************
;; ********************************************************************************
pro rphot_show_image,event
COMPILE_OPT IDL2

;; this is a widget to let the user select which image to display

widget_control,event.top,get_uvalue=data
if (*data).show_image_id ne 0 then begin
    widget_control,(*data).show_image_id,bad_id=isbad
    if isbad eq 0 then begin
        widget_control,(*data).show_image_id,/show
        return
    endif
endif

;; *** this is the top level widget ***
base=widget_base(column=1,/base_align_center,title='RPHOT: Choose Image')

label=widget_label(base,value='Select Image to Display:')

imnames=(*(*data).images).imname
list=widget_list(base,value=imnames,event_pro='rphot_image_selected',uval='list',ysize=10)
widget_control,list,set_list_select=(*data).current_image
(*data).imlist_id=list

botbase=widget_base(base,row=1,/base_align_right)
but=widget_button(botbase,value='Previous',event_pro='rphot_image_selected',uval='previous')
but=widget_button(botbase,value='Redraw',event_pro='rphot_image_selected',uval='redraw')
but=widget_button(botbase,value='Next',event_pro='rphot_image_selected',uval='next')
label=widget_label(botbase,value='    ')
but=widget_button(botbase,value='Do All',event_pro='rphot_image_selected',uvalue='doall')
but=widget_button(botbase,value='Redo All',event_pro='rphot_image_selected',uvalue='redoall')
label=widget_label(botbase,value='    ')
but=widget_button(botbase,value='Done',event_pro='rphot_done',uvalue='show_image',frame=3)

widget_control,base,set_uvalue=data
(*data).show_image_id=base
widget_control,base,group_leader=(*data).main_id

;; show everything
widget_control,base,/realize
xmanager,'select_objects',base,/no_block

end

