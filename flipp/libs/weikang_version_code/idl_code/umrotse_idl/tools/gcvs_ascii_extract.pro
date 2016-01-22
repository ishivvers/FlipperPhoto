pro gcvs_ascii_extract,cat,ral,decl,rah,dech,ind,file

; This program writes out the information Istvan wants to an ascii file.

if N_params() eq 0 then begin
	print,'gcvs_ascii_extract,cat,ral,decl,rah,dech,ind,file'
	return
endif

; First convert the corners to 1950 and select what we want....
ra=ral*15.0
dec=decl
precess,ra,dec,2000.0,1950.0
cral=ra/15.0
cdecl=dec

ra=rah*15.0
dec=dech
precess,ra,dec,2000.0,1950.0
crah=ra/15.0
cdech=dec

print,ral,decl,rah,dech
print,cral,cdecl,crah,cdech

ind=where(cat.ra gt cral and cat.ra lt crah and cat.dec gt cdecl $
	and cat.dec lt cdech)

num=n_elements(ind)

get_lun,f

openw,f,file

for i=0,num-1,1 do begin
   j=ind(i)
;   printf,f,st.ram(j),st.decm(j),st.z(j),st.ze(j),st.m(1,j),st.color(1,j),$
;	st.color(2,j),st.color(3,j),st.color(4,j),$
;	format='(2(f9.3),2(f9.4),5(f8.3))'
   ra=cat.ra(j)
   dec=cat.dec(j)
; Now precess to J2000
   precess,ra*15.0,dec,1950,2000
   printf,f,ra*15.0,dec,'  ',cat.type(j),cat.min(j),cat.max(j),$
	cat.period(j),cat.duration(j),$
	format='(2(f9.5),a2,a8,2(f8.4),2(f12.5))
endfor 

free_lun,f

return
end
