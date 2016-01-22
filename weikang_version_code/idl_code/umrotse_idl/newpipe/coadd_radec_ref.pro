pro coadd_radec_ref,refim,imfile,imtot,weight=weight
;+
; NAME:	COADD_RADEC_REF
;
; CALLING SEQUENCE: coadd_radec_ref,refim,imfile,imtot,weight=weight
;
; INPUTS:	refim; reference image
;		imfile; file containing list of images to use
;
; OUTPUTS:	imtot: sum of all images, weighted to one second!
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Warps the images into coordinates of refim, including handling
;			the missing regions with a weight
;
; REVISION HISTORY:  
;	Tim McKay		UM	12/23/98
;

 if N_params() eq 0 then begin
        print,'Syntax - coadd_radec_ref,refim,imfile,imtot,weight=weight'
        return
 endif

 lr=mrdfits(refim,1,hdr)
 imname=(str_sep(refim,'_cobj'))(0)+'_c.fit'
 imhdr=headfits(refim)
 weight=readfits(imname,hdr)
 weight(*,*)=0.0
 imtot=weight
 
 get_lun,f
 openr,f,imfile

 while not eof(f) do begin
   name=''
   readf,f,name,format='(a60)'
   info=str_sep(name," ")
   namenew=info(0)
   imnamenew=(str_sep(namenew,'_cobj'))(0)+'_c.fit'
   ln=mrdfits(namenew,1,hdr)
   imn=readfits(imnamenew,hdr)
   info=str_sep(namenew,'_1')
   camera=strmid(info(1),0,1)

   hdr=headfits(namenew)
   exptime=sxpar(hdr,'exptime')
   wn=imn
   wn(*,*)=exptime
 
   if (camera eq 'b') then begin
	wn=wn*1.6597
   endif
   if (camera eq 'c') then begin
	wn=wn*1.0895
   endif
   if (camera eq 'd') then begin
	wn=wn*1.4814
   endif
   


;Now actually match these pieces of the two structures
   close_match_radec,lr.ra,lr.dec,ln.ra,ln.dec,m1,m2,0.005,1.0,miss1,/silent

;find the sky in the image and remove it....
   sky,imn,sky,skyerr
   imn=imn-sky

;Now figure out what poly_2d needs
   nobj=n_elements(m1)
   print,'Number of matched objects is: '+string(nobj)
   nl=fix(nobj*0.1)
   nh=fix(nobj*0.5)
   polywarp,ln(m2(nl:nh)).x,ln(m2(nl:nh)).y,lr(m1(nl:nh)).x,lr(m1(nl:nh)).y,2,kx,ky
   imn=poly_2d(imn,kx,ky,cubic=-0.5,missing=0.0)
   wn=poly_2d(wn,kx,ky,cubic=-0.5,missing=0.0)

   imtot=imtot+imn
   weight=weight+wn

 endwhile

 j=where(weight ne 0.0)
 imtot(j)=imtot(j)/weight(j)

 info=str_sep(imname,'_c')
 outname=info(0)+'_template_c.fit'
 sname=info(0)+'_template_sobj.fit'
 sxaddpar,imhdr,'bzero',0.0
 writefits,outname,imtot,imhdr
 rextract_setup,ps
 ps.catalog_name=sname
 ps.detect_thresh=3.0
 ps.analysis_thresh=3.5
 rextract,ps,outname 

 return
 end



