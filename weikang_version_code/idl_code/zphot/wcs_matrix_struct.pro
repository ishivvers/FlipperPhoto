pro wcs_matrix_struct,pixscale,astr

if n_params() eq 0 then begin
  print,'syntax- wcs_matrix_struct,pixscale,astr'
  print,'        pixscale is in unit of arsec'
  return
endif

pixelscale = pixscale/3600.0 ;; change to degree

astr={cd: double(identity(2)),cdelt: [pixelscale,pixelscale], crpix: dblarr(2), crval: dblarr(2)}
return

end
