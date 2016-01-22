pro astr_struct_new,fov,astr

pixscale = double(fov) / 2048d 

astr={cd: double(identity(2)),cdelt: [pixscale,pixscale], crpix: dblarr(2), crval: dblarr(2)}
return
end
