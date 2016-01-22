pro header_update,head,info

if n_params() eq 0 then begin
  print,'syntax - header_update,head,info'
  print,'info is outcome from extract_head_info'
  return
endif

outinfo=info
imhdr=head
sxaddpar,imhdr,'MJD',outinfo.MJD,' Modified Julian day',after='TELESCOP'
sxaddpar,imhdr,'EFFTIME',outinfo.EFFTIME,' effective exposure time (s)',after='TELESCOP'
sxaddpar,imhdr,'EXPTIME',outinfo.EXPTIME,' exposure time (s)',after='TELESCOP'
sxaddpar,imhdr,'FILTER',outinfo.FILTER,' filter',after='TELESCOP'
sxaddpar,imhdr,'PIXSCALE',outinfo.PIXSCALE,' pixel scale of image',after='TELESCOP'
sxaddpar,imhdr,'TEL',outinfo.TEL,' telescope',after='TELESCOP'
;;astr=mrdfits('/home/zwk/idl.lib/kait/kait_astr.fit',1)
;;astr.crval=[outinfo.RAC_RAW,outinfo.DECC_RAW]
;;putast,imhdr,astr
;;print,imhdr
head=imhdr

end
