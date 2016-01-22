pro cobj_update_stars,cobjfile,stars_ra,stars_dec

if n_params() eq 0 then begin
    print,'cobj_update_stars,cobjfile,stars_ra,stars_dec'
    return
endif

if n_elements(stars_ra) ne n_elements(stars_dec) or n_elements(stars_ra) eq 0 then begin
  print,'no star list is given or is empty'
  return
endif

image_name_trans,cobjfile,imnamest
head=headfits(imnamest.cimg)
extast,head,astr
rd2xy,stars_ra,stars_dec,astr,x,y
st0=mrdfits(imnamest.cobj,0,head0)
st1=mrdfits(imnamest.cobj,1,head1)
st2=mrdfits(imnamest.cobj,2,head2)
st1_new=replicate(st1[0],n_elements(x))
st1_new.x=x
st1_new.y=y
st1_new.ra=stars_ra
st1_new.dec=stars_dec

;help,st0
;help,st1
;help,st1_new
;help,st2

writefits,imnamest.cobj,st0,head0
mwrfits,st1_new,imnamest.cobj,head1
mwrfits,st2,imnamest.cobj,head2

end
