function ss_warp,image2,cobj1,cobj2,pixscale=pixscale,kx=kx,ky=ky,fail=fail

if n_params() eq 0 then begin
  print,'syntax- result=ss_warp(image2,cobj1,cobj2,pixscale=pixscale,kx=kx,ky=ky,fail=fail)'
  return,''
endif

if n_elements(pixscale) eq 0 then pixscale=0.0009d

gdref=where(cobj1.flags le 2,ngdref)
gdnew=where(cobj2.flags le 2,ngdnew)

close_match_radec,cobj1[gdref].ra,cobj1[gdref].dec, $
  cobj2[gdnew].ra,cobj2[gdnew].dec,m1,m2,pixscale,1.0,miss1
nobj = n_elements(m1)
    
sz=size(image2)
if ((nobj lt (0.3 * ngdnew)) and (float(nobj)/sz[1]/sz[2] lt 5d-5)) then begin
         print,'Not enough stars matched:',n_elements(m1),' < ',0.3*ngdnew
         fail=1b
         return,''
endif else begin
nl = fix(nobj*0.1)
nh = fix(nobj*0.6)

polywarp,cobj2[gdnew[[m2[nl:nh]]]].x,cobj2[gdnew[[m2[nl:nh]]]].y, $
      cobj1[gdref[[m1[nl:nh]]]].x,cobj1[gdref[[m1[nl:nh]]]].y, 3, kx, ky
pimage2 = poly_2d(image2, kx, ky, 2, missing=0.0, cubic=-0.5)
fail=0b

return,pimage2

endelse

end


