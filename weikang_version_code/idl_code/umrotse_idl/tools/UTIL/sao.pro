PRO sao, image, option

;+
; NAME:
;    SAO
;
; PURPOSE:
;    Call saoimage externally.  You should modify this if your saoimage
;    is not aliased to sao
;-

  IF n_params() LT 1 THEN BEGIN 
      print,'-Syntax: sao, image [,option]'
      return
  ENDIF 

  IF n_elements(option) EQ 0 THEN addoption = '' ELSE addoption = ' -'+option

  dir = '/tmp/'
  file = dir + 'tmp_fchart_'+ntostr(long(systime(1)))+'.fit'

  writefits, file, image

  command1 = 'sao '+file+addoption
  command2 = 'rm '+file

  spawn,command1
  spawn,command2

  return 
END 
