pro tvprint,filename,print=print

;this gets the current display ready to print in an inverse color table 
;and previews it in unix

if n_params() eq 0 then begin
 print,'syntax- tvprint,filename (no suffix!)'
 return
endif

loadct,41,file="$IDL_DIR/resource/colors/colors_nis.tbl"
print,"Writing output to ",filename,".gif"
write_gif,filename+".gif", tvrd()
loadct,0

return
end
