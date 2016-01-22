pro astr_struct_create,astr,pixscale=pixscale

;;pixscale in "/pix from parameter
if not keyword_set(pixscale) then pixscale = 0.7965  ;;this is for kait

pixscale = pixscale/3600d0

astr={cd: double(identity(2)),cdelt: [pixscale,pixscale], crpix: dblarr(2), crval: dblarr(2)}
return
end
