pro  zphot_do_all,data
  for i=0,n_elements( (*(*data).images).imname )-1 do begin
      if finite((*(*data).images)[i].counts[0]) eq 0 then begin
          (*data).current_image=i
          rphot_display_image,data
          rphot_display_closeup,data
          rphot_display_plot,data
      endif
  endfor
end
