pro make_rotse3_subimage,fnames,xcent=xcent,ycent=ycent,racent=racent, $
  deccent=deccent,degrad=degrad,pixrad=pixrad, $
  oname=oname,nocobjcrop=nocobjcrop,square=square, $
  fail=fail,noscale=noscale

if n_params() eq 0 then begin
    print,'syntax- make_rotse3_subimage,fnames,xcent=xcent,ycent=ycent,racent=racent,deccent=deccent,degrad=degrad,pixrad=pixrad,oname=oname,nocobjcrop=nocobjcrop,square=square,fail=fail,noscale=noscale'
    print,'  either xcent/ycent or racent/deccent is required.'
;;    print,'  radius is pixels or degrees, depending'
    print,'  specify pixrad or degrad for radius in pixels or degrees'
    print,'  the output name is returned in oname'
endif

fail = 0 

;; check how the program was called; make sure everything is kosher
use_xcent = 0
use_racent = 0
if n_elements(xcent) gt 0 and n_elements(ycent) gt 0 then begin
    use_xcent = 1
endif

if n_elements(racent) gt 0 and n_elements(deccent) gt 0 then begin
    use_racent = 1
endif

if use_xcent and use_racent then begin
    print,'Can only specify one of xcent/ycent or racent/deccent'
    fail = 1
    return
endif else if not use_xcent and not use_racent then begin
    print,'Must specify at least one of xcent/ycent or racent/deccent'
    fail = 1
    return
endif

use_degrad = 0
use_pixrad = 0
if (n_elements(degrad) gt 0) then begin
    use_degrad = 1
endif
if (n_elements(pixrad) gt 0) then begin
    use_pixrad = 1
endif

if use_pixrad and use_degrad then begin
    print,'Can only specify radius in pixels or degrees'
    fail = 1
    return
endif else if not use_degrad and not use_pixrad then begin
    print,'must specify at least one of degrad or pixrad'
    fail = 1
    return
endif

for i=0l,n_elements(fnames)-1 do begin
    fname=fnames[i]
    fail = 0

    ;; read in the image
    full_fname = find_rotse3_image(fname,path=['./image','.'],fail=fail)
    if (fail) then begin
        print,'Could not find image: '+ fname
        fail = 1
;;        return
    endif
    
    full_cobj = find_rotse3_cobj(fname,path=['./prod','.'],fail=fail)
    if (fail) then begin
        print,'Could not find cobj: '+fname
        fail = 1
        ;;      return
    endif

    if (fail eq 0) then begin

        im=readfits(full_fname,imhdr)
        c=mrdfits(full_cobj,1)
        cal=mrdfits(full_cobj,2)

        nx=sxpar(imhdr,'NAXIS1')
        ny=sxpar(imhdr,'NAXIS2')

        if (use_xcent) then begin
            if (use_pixrad) then begin
                radius = pixrad
            endif else begin
                astr_struct_new,1.85,astr
                radius = degrad / astr.cdelt[0]
            endelse

            xlow = fix(xcent - radius)
            xhigh = fix(xcent + radius)
            ylow = fix(ycent - radius)
            yhigh = fix(ycent + radius)

            ;; and we need to figure out the ra/dec limits
            astr_struct_new,1.85,astr
            astr.crval=[double(cal.rac),double(cal.decc)]
            kmap_inv,[xcent,xlow,xhigh,c.x],[ycent,ylow,yhigh,c.y],xp,yp,cal.kx,cal.ky
            xy2rd,xp[0:2],yp[0:2],astr,r,d
            decliml = min(d)
            declimh = max(d)
            raliml = min(r)
            ralimh = max(r)

            racent = xp[0]
            deccent = yp[0]

        endif else begin
            if (use_pixrad) then begin
                astr_struct_new,1.85,astr
                radius = pixrad * astr.cdelt[0]
            endif else begin
                radius = degrad
            endelse

            decliml = deccent - radius
            declimh = deccent + radius
            raliml = racent - (radius / cos(deccent * 0.01745))
            ralimh = racent + (radius / cos(deccent * 0.01745))

            astr_struct_new,1.85,astr
            astr.crval=[double(cal.rac),double(cal.decc)]
            rd2xy,[raliml,ralimh],[decliml,declimh],astr,xc,yc
            kmap,xc,yc,xx,yy,cal.kx,cal.ky
            
            rd2xy,racent,deccent,astr,xc,yc
            kmap,xc,yc,xa,ya,cal.kx,cal.ky
            xcent = round(xa[0])
            ycent = round(ya[0])

            ;; does this need to be square?  it might, so set square below
            if (use_pixrad) then begin
                xlow = fix(xcent - pixrad)
                xhigh = fix(xcent + pixrad)
                ylow = fix(ycent - pixrad)
                yhigh = fix(ycent + pixrad)
            endif else begin
                xlow = round(min(xx))
                xhigh = round(max(xx))
                ylow = round(min(yy))
                yhigh = round(max(yy))
            endelse

        endelse

        if (xcent ge nx) or (xcent lt 1) or (ycent ge ny) or (ycent lt 1) then begin
            print,'Position not in image!'
            fail = 1
            return
        endif

        if (xlow lt 0) then xlow = 0
        if (xhigh ge nx) then xhigh = nx - 1
        if (ylow lt 0) then ylow = 0
        if (yhigh ge ny) then yhigh = ny - 1

        if keyword_set(square) then begin
            new_nx = xhigh - xlow + 1
            new_ny = yhigh - ylow + 1
            
            if (new_nx) ne (new_ny) then begin
                if (new_nx lt new_ny) then begin
                    ;; we need to shorten the y (which was already in range)
                    diff = new_ny - new_nx
                    ylow = ylow + diff / 2
                    yhigh = yhigh - diff / 2 - (diff mod 2)
                endif else begin
                    ;; we need to shorten the x (which was already in range)
                    diff = new_nx - new_ny
                    xlow = xlow + diff / 2
                    xhigh = xhigh - diff / 2 - (diff mod 2)
                endelse
            endif
        endif

;; now figure out the name
        dirparts=strsplit(full_fname,'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

        if (use_xcent) then begin
            ;; name is in x/y space
            onamebase=parts[0]+'_'+parts[1]+'-'+string(xcent,format='(i4.4)')+'-'+string(ycent,format='(i4.4)')+'_'+parts[2]
        endif else begin
            ;; name is in ra/dec space
            rabits = sixty(racent / 15.)
            decsign = '+'
            if (deccent lt 0) then decsign = '-'
            decbits = sixty(abs(deccent))
            onamebase=parts[0]+'_'+parts[1]+'-'+ $
                      string(fix(rabits[0]),format='(i2.2)') + $
                      string(fix(rabits[1]),format='(i2.2)') + $
                      string(fix(rabits[2]),format='(i2.2)') + $
                      decsign + $
                      string(fix(decbits[0]),format='(i2.2)') + $
                      string(fix(decbits[1]),format='(i2.2)') + $
                      string(fix(decbits[2]),format='(i2.2)') + $
                      '_' + parts[2]
        endelse


        oname = onamebase + '_c.fit'
        oname_cobj = onamebase + '_cobj.fit'

;; modify the cobjfile
        h=where(c.ra gt raliml and c.ra lt ralimh and c.dec gt decliml and c.dec lt declimh,ct)

        if (ct eq 0) then begin
            print,'No cobj objects in the subregion?'
            fail = 1
            return
        endif



        cnew=c[h]
        imhdrnew = imhdr

;; add in a new imsub guy to cal
        tempstr=create_struct('imsub','')
        combine_structs,cal,temporary(tempstr),calnew

        cnew.x = cnew.x - xlow
        cnew.y = cnew.y - ylow
        calnew.kx[0,0] = calnew.kx[0,0] - xlow
        calnew.ky[0,0] = calnew.ky[0,0] - ylow
        sxaddpar,imhdrnew,'CRPIX1',sxpar(imhdr,'CRPIX1')-xlow
        sxaddpar,imhdrnew,'CRPIX2',sxpar(imhdr,'CRPIX2')-ylow
        calnew.crpix1 = sxpar(imhdrnew,'CRPIX1')
        calnew.crpix2 = sxpar(imhdrnew,'CRPIX2')


;; and record the subframe stuff
        imsubstring = string(xlow,format='(i4.4)') + ':' + $
                      string(xhigh,format='(i4.4)') + ',' + $
                      string(ylow,format='(i4.4)') + ':' + $
                      string(yhigh,format='(i4.4)')

        sxaddpar,imhdrnew,'IMSUB',imsubstring
        calnew.imsub = imsubstring


;; crop and write out the image -- use bzero/bscale

        ncoadd=sxpar(imhdr,'NCOADD')
        if (ncoadd eq 1) and (not keyword_set(noscale)) then begin
            bzero = sxpar(imhdr,'O_BZERO')
            bscale = sxpar(imhdr,'O_BSCALE')
            if (bzero eq 0) or (bscale eq 0) then begin
                bzero = sxpar(imhdr,'BZERO')
                bscale = sxpar(imhdr,'BSCALE')
            endif
            
            imnew = im[xlow:xhigh,ylow:yhigh]
            shortimnew = fix(round(imnew - bzero)/bscale)
            
            sxaddpar,imhdrnew,'BZERO',bzero
            sxaddpar,imhdrnew,'BSCALE',bscale
            sxaddpar,imhdrnew,'NAXIS1',n_elements(shortimnew[*,0])
            sxaddpar,imhdrnew,'NAXIS2',n_elements(shortimnew[0,*])
            sxaddpar,imhdrnew,'FILENAME',oname
            sxaddpar,imhdrnew,'SUB_RA',racent
            sxaddpar,imhdrnew,'SUB_DEC',deccent
            sxaddpar,imhdrnew,'SUB_RAD',radius   ;; won't work for x/ycent, ugh

            calnew.bzero = bzero
            calnew.bscale = bscale
            calnew.naxis1 = sxpar(imhdrnew,'NAXIS1')
            calnew.naxis2 = sxpar(imhdrnew,'NAXIS2')
            calnew.filename = oname
            calnew.fname = oname


            print,n_elements(shortimnew[*,0]),n_elements(shortimnew[0,*])

            writefits,oname,shortimnew,imhdrnew
        endif else begin
            imnew=im[xlow:xhigh,ylow:yhigh]

            sxaddpar,imhdrnew,'NAXIS1',n_elements(imnew[*,0])
            sxaddpar,imhdrnew,'NAXIS2',n_elements(imnew[0,*])
            sxaddpar,imhdrnew,'FILENAME',oname
            sxaddpar,imhdrnew,'SUB_RA',racent
            sxaddpar,imhdrnew,'SUB_DEC',deccent
            sxaddpar,imhdrnew,'SUB_RAD',radius   ;; won't work for x/ycent, ugh

            calnew.naxis1 = sxpar(imhdrnew,'NAXIS1')
            calnew.naxis2 = sxpar(imhdrnew,'NAXIS2')
            calnew.filename = oname
            calnew.fname = oname

            print,n_elements(imnew[*,0]),n_elements(imnew[*,0])

            writefits,oname,imnew,imhdrnew
        endelse

;; and write out the cobj if desired
        if not keyword_set(nocobjcrop) then begin
            dummyhdr = imhdrnew
            writefits,oname_cobj,indgen(10,10),dummyhdr
            mwrfits,cnew,oname_cobj
            mwrfits,calnew,oname_cobj
        endif
    endif
endfor



return
end
