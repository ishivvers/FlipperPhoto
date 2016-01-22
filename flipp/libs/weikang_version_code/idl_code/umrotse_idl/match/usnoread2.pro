pro usnoread2,ra,dec,size,cat,maglim=maglim,catdir=catdir

 if n_params() lt 4 then begin
     print,'syntax- usnoread2,ra,dec,size,cat,maglim=maglim,catdir=catdir'
     return
 endif

 if n_elements(maglim) eq 0 then maglim = 50.0

 t = systime(1)

 rotse_setup

 if n_elements(catdir) eq 0 then catdir = !usno_catdir

 elt = create_struct(name='ucat', 'ra', 0d, 'dec', 0d, $
                     'rmag', 1000.0, 'bmag', 1000.0)
 cat = elt

 ra = double(ra)
 dec = double(dec)
 size = double(size)

 if (ra lt 0.0 or ra gt 360.0) then begin
     print,'RA value out of bounds'
     cat = -1
     return
 endif
 if (dec lt -90.0 or dec gt 90.0) then begin
     print,'Dec value out of bounds'
     cat = -1
     return
 endif

 mindec = dec - size
 maxdec = dec + size
 minhr = (ra - size)/15.
 maxhr = (ra + size)/15.

 if (minhr le 0.0) then minhr = 24.0 + minhr
 if (maxhr gt 24.0) then maxhr = maxhr - 24.0

 zones = intarr(2)
 hours = fltarr(2)

 zones[0] = fix(floor((mindec + 90.)/7.5)*75)
 zones[1] = fix(floor((maxdec + 90.)/7.5)*75)

 hours[0] = floor(minhr/0.25)*0.25
 hours[1] = floor(maxhr/0.25)*0.25

 z=0
 while (z le n_elements(zones)-1) do begin
     accfile = catdir + 'zone' + string(zones[z],format='(i4.4)')+'.acc'
     catfile = catdir + 'zone' + string(zones[z],format='(i4.4)')+'.cat'

     readcol,accfile,hrs,offsets,sizes,format='F,L,L',/silent

     ;; check for 360 degree crossing

     if (hours[0] gt hours[1]) then begin
         indices = where(hrs ge hours[0] or hrs le hours[1])
     endif else begin
         indices = where(hrs ge hours[0] and hrs le hours[1])
     endelse

     openr,lun,catfile,/get_lun,/swap_if_little_endian

     for i=0l,n_elements(indices)-1 do begin
         the_offset = (offsets[indices[i]] - 1) * 3 * 4
         num_elements = sizes[indices[i]]

         raw_data_chunk = replicate(0L,3,num_elements)

         temp_cat = replicate(elt, num_elements)

         point_lun,lun,the_offset
         readu,lun,raw_data_chunk

         temp_cat.ra = double(reform(raw_data_chunk[0,*])) / (3600d * 100d)
         temp_cat.dec = double(reform(raw_data_chunk[1,*])) / (3600d * 100d) - 90d
         temp_cat.rmag = abs((reform(raw_data_chunk[2,*]) mod 1000)/10.0)
         temp_cat.bmag = abs(((reform(raw_data_chunk[2,*]) mod 1000000)/1000)/10.0)

         cat = [cat,temp_cat]

     endfor
     free_lun,lun

     z=z+1
     if (zones[1] eq zones[0]) then z = n_elements(zones)
 endwhile
 ;; and now, the 360 problem

 if (minhr gt maxhr) then begin
     h=where(((cat.ra le maxhr * 15d) or (cat.ra ge minhr * 15d)) and $
             (cat.dec ge mindec) and (cat.dec le maxdec) and $
             (cat.rmag le maglim), count)

 endif else begin
     h=where((cat.ra ge minhr * 15d) and (cat.ra le maxhr * 15d) and $
             (cat.dec ge mindec) and (cat.dec le maxdec) and $
             (cat.rmag le maglim), count)
 endelse
             
 if (count eq 0) then begin
     print,'something screwy'
     cat = -1
     return
 endif

 print,count,' objects found.'

 cat = cat[h]

 print,systime(1)-t


 return
end
