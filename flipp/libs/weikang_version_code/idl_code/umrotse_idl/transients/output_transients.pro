pro output_transients,tstr,mt,sts,appendobs,conf=conf

if n_params() eq 0 then begin
    print,'syntax- output_transients,tstr,mt,sts,appendobs,conf=conf'
    return
endif

if n_elements(conf) gt 0 then begin
    workdir = conf.workdir
    bindir = conf.bindir
endif else begin
    workdir = './'
    bindir = './'
endelse

parts=str_sep(mt.imagename[appendobs[0]],'_')
datestr = parts[0]
camstr = strmid(parts[2],0,2)

;;for i=0l,n_elements(trans)-1 do begin
for i=0l,n_elements(tstr.check)-1 do begin
    trans = tstr.check[i].objind

    ;; first figure out the name
    print,'Working on transient ' + string(trans,format='(i5)') + $
          ' at ' + string(mt.ra[trans],format='(f12.7)') + $
          ' ' + string(mt.dec[trans],format='(f12.7)')

    rabits = sixty(mt.ra[trans]/15d)
    decbits = sixty(abs(mt.dec[trans]))
    sign = '+'
    if (mt.dec[trans] lt 0.0) then sign = '-'

    fname_base=datestr+'_trans_'+string(rabits[0],format='(i2.2)') + $
               string(rabits[1],format='(i2.2)') + $
               string(rabits[2],format='(i2.2)') + sign + $
               string(decbits[0],format='(i2.2)') + $
               string(decbits[1],format='(i2.2)') + $
               string(decbits[2],format='(i2.2)') + '_' + $
               camstr
    ;; then write the binary file
    tempsts=sts
    tempsts[0].trig_ra = mt.ra[trans]
    tempsts[0].trig_dec = mt.dec[trans]
    write_binary,mt,tempsts,trans,0.0,0.0,0,0.0, $
      workdir + '/' + fname_base + '.bin',fail=fail,/notjd

    if (fail) then print,'Failed to write binary file.'

    ;; finally, write out the jpeg
    write_transient_jpeg,tstr,i,mt,sts,workdir + '/' + fname_base

    ;; and move them to the directory
    if n_elements(conf) ne 0 then begin
        cmd = 'mv '+workdir+'/'+fname_base +'* ' + bindir
        spawn,cmd
        cmd = 'touch ' + conf.thumbfile
        spawn,cmd
    endif
endfor


return
end
