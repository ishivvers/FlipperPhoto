pro kait_ss_loop,cobjlist, ref,subreg=subreg

if n_params() eq 0 then begin
  print,'syntax - kait_ss_loop,cobjlist, ref,subreg=subreg'
  print,'subreg = 1: percent, say 0.9'
  print,'subreg = 2: given reg, say [100,400,100,400] (equal to [100:400,100:400])'
  return
endif

tnb=n_elements(cobjlist)

for i=0,tnb-1 do begin

  image_name_trans,cobjlist[i],imagest
  
  fi=findfile(imagest.cimg)
  
  if fi[0] eq '' then begin
    print,'file : ',imagest.cimg,' not found, quit!'
    return
  endif

  ;; Now warp the image
  print,cobjlist[i],ref
  kait_warp_tf_ref,cobjlist[i],ref,/save,/from
  ;;use wcs trans
  ;image_warpwcs_tf_ref,cobjlist[i],ref,/from
  print,cobjlist[i],ref

  fr=findfile(imagest.cfwp)
  if fr[0] eq '' then begin
    print,'file : ',imagest.cfwp,' not found, quit!'
    return
  endif
  
  kait_subtract_isis,imagest.cimg,imagest.cfwp,subreg=subreg
endfor

end
