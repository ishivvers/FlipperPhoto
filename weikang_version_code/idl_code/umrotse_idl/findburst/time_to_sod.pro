pro time_to_sod,timestring,sec_o_day,t0,delay

; Created 4-23-99 Bob Kehoe

if N_params() lt 2 then begin
   print, 'Syntax time_to_sod,timestring,sec_o_day'
   return
endif

x=str_sep(timestring,':')
y=str_sep(x(2),'.')
sec_o_day = x(0)*3600.0 + x(1)*60.0 + y(0) + y(1)*0.01 
delay = sec_o_day - t0
print, delay

end
