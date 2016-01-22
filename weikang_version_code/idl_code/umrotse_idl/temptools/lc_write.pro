pro lc_write,st,ind,obj,file

; This program writes out a light curve in jd, m, merr format....

if N_params() eq 0 then begin
	print,'lc_write,st,ind,obj,file'
	return
endif

num=n_elements(ind)

get_lun,f

openw,f,file

for i=0,num-1,1 do begin
   j=ind(i)
;   printf,f,st.m(1,j),st.ug(j),st.gr(j),st.ri(j),st.iz(j),st.fwhm(1,j),$
;	st.ra(j),st.dec(j),st.x(1,j),st.y(1,j),$
;	format='(6(f7.3),4(f9.3))'
   printf,f,st.jd(j)-50900.0D,st.m(j,obj),st.merr(j,obj),format='(3f15.8)'
endfor 

free_lun,f

return
end
