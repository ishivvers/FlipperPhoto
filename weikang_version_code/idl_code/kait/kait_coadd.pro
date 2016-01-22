pro kait_coadd, cobjlist, outfile=outfile,ref=ref

if n_params() eq 0 then begin
  print,'syntax - cobjlist, outfile=outfile'
  return
endif

tnb=n_elements(cobjlist)
if tnb le 1 then begin
  print,'Not enough image for co-adding!'
  return
endif

if not keyword_set(ref) then template=cobjlist[0] else template=ref

image_name_trans,template,imnamest

if not keyword_set(outfile) then outfile=imnamest.root+'_coadd_c.fit'
image_name_trans,outfile,outnamest
;help,outnamest

if not keyword_set(ref) then begin
  firstim=mrdfits(imnamest.CIMG,0,outimhead,/fscale,/silent)
endif else begin
  outimhead=headfits(imnamest.CIMG)
  kait_warp_tf_ref,cobjlist[0],template,newim=newim
  firstim=newim
endelse

outim=firstim

for i=1,tnb-1 do begin
  kait_warp_tf_ref,cobjlist[i],template,newim=newim
  outim=outim+newim
endfor

;Now set the correct mjd and exptime

mjd=0
exptime=0
for i=0,tnb-1 do begin
  sttemp=mrdfits(cobjlist[i],2,/silent)
  mjd=mjd+sttemp.mjd
  exptime=exptime+sttemp.EFFTIME
  sxaddpar,outimhead,'COMMENT', ': coadd image of '+cobjlist[i]
endfor
mjd=mjd/float(tnb)
;print,outimhead

;Now write cimage file
writefits,outfile,outim,outimhead
;Now write cobj file, using the ref cobjfile but with updated mjd and exptime
st0=mrdfits(template[0],0,head0,/silent)
st1=mrdfits(template[0],1,head1,/silent)
st2=mrdfits(template[0],2,head2,/silent)
st2.mjd=mjd
st2.exptime=exptime
writefits,outnamest.cobj,st0,head0
mwrfits,st1,outnamest.cobj
mwrfits,st2,outnamest.cobj


end
