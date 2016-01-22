pro find_ivar,mlist,var,ivars

; Created:  9-1-00  Bob Kehoe

len = (size(mlist))[1]
ivars = intarr(len)
for k = 0,len-1 do begin
   i = where(var.ptr eq mlist[k], count)
   if (count eq 1) then ivars[k] = i
endfor

end
