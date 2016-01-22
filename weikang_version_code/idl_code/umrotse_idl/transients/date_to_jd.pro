pro date_to_jd,monthstr,day,year,timestr,jd,fail=fail

if n_params() eq 0 then begin
    print,'date_to_jd,monthstr,day,year,timestr,jd,fail=fail'
    return
endif

fail=0

month = 0
case monthstr of
   'Jan': month = 1
   'Feb': month = 2
   'Mar': month = 3
   'Apr': month = 4
   'May': month = 5
   'Jun': month = 6
   'Jul': month = 7
   'Aug': month = 8
   'Sep': month = 9
   'Oct': month = 10
   'Nov': month = 11
   'Dec': month = 12
endcase

if (month eq 0) then begin
    print,'illegal month'
    jd = 0d
    fail = 1
    return
endif

parts=strsplit(timestr,':',/extract)
if n_elements(parts) eq 1 then begin
    year = long(parts[0])
    hour = 0
    min = 0
endif else begin
    hour = long(parts[0])
    min = long(parts[1])
endelse

jd = julday(month,day,year,hour,min,0.0)


return
end
