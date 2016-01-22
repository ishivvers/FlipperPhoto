pro query_no_jpeg,st,en,fname,dim=dim

if n_params() eq 0 then begin
    print,'syntax- query_no_jpeg,st,en,fname,dim=dim'
    return
endif

if n_elements(dim) ne 2 then dim=[400,400]

set_plot,'z'
setupplot
device,set_resolution=dim
erase
text = 'No Image From Frames ' + string(st,format='(i2)') + ' - ' + string(en,format='(i2)')
xyouts,dim/2,dim/2,text,alignment=0.5,/device
write_jpeg,fname,tvrd()

return
end
