pro generic_dialog_events, event
  eventname = tag_names(event, /structure_name)
  if eventname eq 'WIDGET_BUTTON' then begin
      widget_control,event.top,get_uvalue=info,/no_copy
      widget_control,event.id,get_value=buttonvalue
      case buttonvalue of
          'Accept': begin
              widget_control, info.inputid, get_value=input_str
              (*info.ptr).input_str = input_str
              (*info.ptr).cancel = 0
          end
          'Cancel': begin
              (*info.ptr).input_str = ''
          end
      endcase
      widget_control,event.top,/destroy
  endif
end

function generic_dialog, parent=parent,default=default,text=text

if n_elements(default) eq 0 then begin
    default=''
endif

input_str=string(default)

;;device,get_screen_size=screensize


if n_elements(parent) gt 0 then begin
    tln = widget_base(column=1, title=text, /modal, group_leader=parent,/floating, $
                      /base_align_center)
endif else begin
    tln = widget_base(column=1,title=text,/base_align_center)
endelse

subbase = widget_base(tln, column=1, frame=1)
fsize=strlen(input_str) * 2
if fsize lt 10 then fsize = 10
inputid = cw_field(subbase, title=(text+':'), value=input_str, xsize=fsize)

butbase = widget_base(tln, row=1)

cancbase = widget_base(butbase)
cancel = widget_button(cancbase,value='Cancel')
accbase = widget_base(butbase)
accept = widget_button(accbase, value='Accept')

widget_control,tln,default_button=accept,cancel_button=cancel

widget_control,tln,/realize

ptr=Ptr_New({input_str:'', cancel:1})
inputinfo = {inputid:inputid, ptr:ptr}
widget_control,tln,set_uvalue=inputinfo,/no_copy

xmanager,text,tln,event_handler='generic_dialog_events'

inputinfo = *ptr
ptr_free,ptr

return,inputinfo.input_str
end
