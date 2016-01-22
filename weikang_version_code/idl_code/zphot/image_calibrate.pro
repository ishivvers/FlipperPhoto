pro image_calibrate,imagenames,catalog

if n_params() eq 0 then begin
  print,'syntax- image_calibrate,imagename,catalog'
  print,'catalog structure must have: .Ra, .Dec, .Mag'
  return
endif

if n_elements(catalog) le 3 then begin
  print,'catalog must have >3 stars and the structure must have: .Ra, .Dec, .Mag'
  return
end

tnf=n_elements(imagenames)
for i=0,tnf-1 do begin
  image_name_trans,imagenames[i],imagest

  ;;first of all, use Ssex_kait_wcs to extract sobjfile
  cmd='/home/zwk/bin/Ssex_kait_wcs '+imagenames[i]
  spawn,cmd
  print,imagest.sobj
  sobjclean,imagest.sobj
  sobj_triangle_match,imagest.sobj,catalog,outast=outast,fail=fail
  if fail then begin
    print,'Fail for image : ',imagenames[i]
    continue
  endif
  im=mrdfits(imagenames[i],0,head)
  extract_head_info,imagenames[i],outinfo=outinfo
  header_update,head,outinfo
  putast,head,outast
  writefits,imagest.CIMG,im,head
endfor

end

