pro print_var, match,var,fname=fname

; Created:  05-31-00  Bob Kehoe

if N_params() lt 2 then begin
   print, 'Syntax print_var,match,var,fname=fname'
   return
endif

num = (size(var.ptr))[1]

if keyword_set(fname) then begin
   lun = 5
   openw,lun,fname
   for k = 0,num-1 do begin
      h = where(match.m[*,var.ptr[k]] gt -1.0)
      printf, lun, 'K =', var.ptr[k], ':  RA=', match.ra[var.ptr[k]], $
		' DEC=', match.dec[var.ptr[k]]
      printf, lun, '     avgmag, delta = ',var.avgmag[k],var.delta[k]
      printf, lun, '     mag = ',match.m[h,var.ptr[k]]
      printf, lun, '     dis = ',var.dis[h,k]
      printf, lun, '     eflags = ',match.flags[h,var.ptr[k]]
      printf, lun, '     msys = ',match.msys[h,var.ptr[k]]
      printf, lun, '     rflags = ',match.rflags[h,var.ptr[k]]
   endfor
   printf, lun, ' '
   printf, lun, ' '
   printf, lun, ' '
   for k = 0,num-1 do printf, lun, var.name[k], var.maxdelta[k], $
			var.maxerr[k], var.chisq_clip[k]
   printf, lun, ' '
   printf, lun, ' '
   printf, lun, ' '
   for k = 0,num-1 do begin
	printf, lun, var.name[k], var.delta[k], var.avgmag[k], $
			match.ra[var.ptr[k]], match.dec[var.ptr[k]]
   endfor
   close,lun
endif else begin
   for k = 0,num-1  do begin
      h = where(match.m[*,var.ptr[k]] gt -1.0)
      print, 'K =',var.ptr[k], ':  RA=',match.ra[var.ptr[k]],' DEC=',$
		match.dec[var.ptr[k]]
      print, '     avgmag, delta = ',var.avgmag[k],var.delta[k]
      print, '     mag = ',match.m[h,var.ptr[k]]
      print, '     dis = ',var.dis[h,k]
      print, '     eflags = ',match.flags[h,var.ptr[k]]
      print, '     msys = ',match.msys[h,var.ptr[k]]
      print, '     rflags = ',match.rflags[h,var.ptr[k]]
   endfor
   print, ' '
   print, ' '
   print, ' '
   for k = 0,num-1 do print, var.name[k], var.maxdelta[k], $
			var.maxerr[k], var.chisq_clip[k]
   print, ' '
   print, ' '
   print, ' '
   for k = 0,num-1 do begin
	print, var.name[k], var.delta[k], var.avgmag[k], $
			match.ra[var.ptr[k]], match.dec[var.ptr[k]]
   endfor
endelse

end


