pro flag_usno_objects,m,ucat=ucat,radius=radius

if n_params() eq 0 then begin
    print,'syntax- flag_usno_objects,m,ucat=ucat,radius=radius'
    return
endif

if n_elements(ucat) eq 0 then begin
    read_ucat_match,m,ucat
endif

if n_elements(radius) eq 0 then begin
    radius = 2 * 0.0009d
endif

h=where(check_flags3('USNOCAT',m.rflags[0,*],type='RFLAGS') eq 0)

close_match_radec,m.ra[h],m.dec[h],ucat.ra,ucat.dec,m1,m2,radius,1,miss


if (m1[0] ne -1) then begin
    m.rflags[0,h[m1]] = set_flags3('USNOCAT',old=m.rflags[0,h[m1]],type='RFLAGS')
endif

return
end
