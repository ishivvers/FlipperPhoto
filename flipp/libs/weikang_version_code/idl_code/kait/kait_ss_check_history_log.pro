pro kait_ss_check_history_log,fieldname,inputinfo,outputinfo

if n_params() eq 0 then begin
    print,'kait_ss_check_history_log,fieldname,inputinfo,outputinfo'
    return
endif

ss_field_history_dir='/kait/web/ss_field_history/'

logfile=ss_field_history_dir+fieldname+'_log.fit'

f=findfile(logfile)

outputinfo=inputinfo
;help,outputinfo
;print,outputinfo
;print,'check'

if f[0] eq '' then begin
  print,'Not find history logfile : ',logfile,' , creating one'
  wsttofile,logfile,inputinfo
  return
endif

logs=mrdfits(f[0],1,/silent)

pixscale=0.7965/3600.0


tnf=n_elements(logs)
detectedtimes=0.0
for i=0,tnf-1 do begin

  close_match_radec,inputinfo.ra,inputinfo.dec, logs[i].ra,logs[i].dec,m1,m2,pixscale*3.0,1.0,miss1,/silent
  ;print,logs[i]
  if m1[0] ne -1 then begin
    outputinfo=logs[m2[0]]
    detectedtimes=detectedtimes+1
  endif
endfor
;print,tnf
outputinfo.totaltimes=tnf
outputinfo.detectedtimes=detectedtimes
;print,'done check'
;print,outputinfo

logs=[logs,inputinfo]
wsttofile,logfile,logs

end
