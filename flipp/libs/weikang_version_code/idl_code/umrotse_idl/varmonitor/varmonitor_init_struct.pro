pro varmonitor_init_struct,var,site,dir=dir

if n_params() eq 0 then begin
    print,'syntax- varmonitor_init_struct,var,site,dir=dir'
    return
endif

if n_elements(dir) eq 0 then dir = '/rotse/data/pipeline/templates/varmonitor/'

radec=strmid(var.ra,0,2)+strmid(var.ra,3,2) + $
  strmid(var.dec,0,3)+strmid(var.dec,4.2)

varfname = dir + 'vm_' + var.filename + '_3' + site + '.fit'
test=findfile(varfname,count=ct)

if (ct eq 1) then begin
    print,'File '+varfname+' already exists.'
    return
endif

varstr=varmonitor_make_struct(1)
varstr.name=var.name
varstr.position=radec
varstr.othername=var.othername
varstr.ra=var.rad
varstr.dec=var.decd

mwrfits,varstr,varfname,/create

return
end
