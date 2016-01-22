pro calc_cobj_key,filename,key1,key2

if n_params() eq 0 then begin
    print,'Syntax- calc_cobj_key,filename,key1,key2'
    print,'   Since IDL databases cannot handle 64bit longs, we need two keynums'
    return
endif

  key1=long(0)
  key2=long(0)

  key=long64(0)


  parts = str_sep(filename,'_')

  if n_elements(parts) lt 3 then begin
      print,'filename parse error'
      return
  endif

  ; This will need to be modified to handle ROTSE-III field names

  datenum=long64(parts(0))
  key = key + datenum*1000000000000

 
  field=long64(strmid(parts(1),3))
  key = key + field*10000

  frame=long64(strmid(parts(2),2,3))
  key = key + frame*10

  camera=strmid(parts(2),0,2)
  case camera of
      '1a': key = key + 1
      '1b': key = key + 2
      '1c': key = key + 3
      '1d': key = key + 4
  endcase

  key1 = long(key / 1000000000)
  key2 = long(key mod 1000000000)


return

end
