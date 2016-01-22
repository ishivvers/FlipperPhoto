pro simtrans_add_stars,fname,ras,decs,mags,outname_root,m_lim,simtransdir=simtransdir

if n_params() eq 0 then begin
    print,'syntax- simtrans_add_star,fname,ras,decs,mags,outname_root,m_lim,simtransdir=simtransdir'
    return
endif

if n_elements(simtransdir) eq 0 then simtransdir = '.'

test=findfile('-d '+simtransdir,count=ct)
if (ct eq 0) then begin
    print,'simtransdir '+simtransdir+' does not exist.  Exiting.'
    return
endif

imname=find_rotse3_image(fname,path='./image')
cobjname=find_rotse3_cobj(fname,path='./prod')
sobjname=find_rotse3_cobj(fname,path='./prod',/sobj)

;;print,imname
;;print,cobjname
;;print,sobjname

im=readfits(imname,hdr)
cobj=mrdfits(cobjname,1)
cal=mrdfits(cobjname,2)
sobj=mrdfits(sobjname,1)
shdr=headfits(sobjname)

m_lim = cal.m_lim

flagpos = intarr(n_elements(ras)) + 1

;; should make sure in image
for i=0l,n_elements(ras)-1 do begin
    if (ras[i] lt cal.ra_low or ras[i] gt cal.ra_high or decs[i] lt cal.dec_low or $
        decs[i] gt cal.dec_high) then begin
        print,'a position not in range'
        ;;return
        flagpos[i] = 0
    endif
endfor

to_add = where(flagpos eq 1)

add_stars_to_image,im,cobj,cal,sobj,shdr,ras[to_add],decs[to_add],mags[to_add],im_new

;; now, figure out the filename
outdir = simtransdir + '/image/'

test=findfile('-d '+outdir,count=ct)
dparts=strsplit(imname,'/',/extract)
parts=strsplit(dparts[n_elements(dparts)-1],'_',/extract)

newdate = '1' + strmid(parts[0],1,5)

if (ct gt 0) then begin
    full_out_name = outdir + newdate + '_' + parts[1] + '_' + parts[2] + '_c.fit'
endif else begin
    print,'there does not appear to be an image subdirectory.  saving in simtransdir'
    full_out_name = simtransdir + '/' + newdate + '_' + parts[1] + '_' + parts[2] + '_c.fit'
endelse

outname_root = newdate + '_' + parts[1] + '_' + parts[2]

;; and write it out, compressed
bzero = sxpar(hdr,'O_BZERO')
bscale = sxpar(hdr,'O_BSCALE')

if (bzero eq 0) or (bscale eq 0) then begin
    bzero = sxpar(hdr,'BZERO')
    bscale = sxpar(hdr,'BSCALE')
endif

sxaddpar,hdr,'BZERO',bzero
sxaddpar,hdr,'BSCALE',bscale
short_im=fix(round(im_new-bzero)/bscale)

sxaddpar,hdr,'FILENAME',outname_root + '.fit'

print,bzero, bscale, min(short_im),max(short_im)

;;writefits,full_out_name,im_new,hdr
writefits,full_out_name,short_im,hdr



return
end
