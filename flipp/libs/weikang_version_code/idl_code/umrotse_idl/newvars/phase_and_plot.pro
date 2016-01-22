pro phase_and_plot,fname,freq,numknots,wait=wait

  
if N_params() eq 0 then begin
   print,'Syntax: phase_and_plot,fname,freq,numknots,wait=wait'
   return
endif
    
if keyword_set(wait) then twait=wait

num=n_elements(freq)

for num=0,num-1 do begin
  format_freq_cmd='format_freq '+fname+' '+string(freq(num),format='(f16)')+ $
                    ' '+string(numknots)
  spawn,format_freq_cmd
  plot_freqp,fname
  if keyword_set(wait) then wait,twait
endfor


return

end


