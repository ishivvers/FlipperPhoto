pro array_moments,struct,mag_moments

 if N_params() eq 0 then begin
        print,'Syntax - array_moments,struct,mag_moments'
        return
 endif

 info=size(struct.m(1,*))
 number=info(2)

 output=findgen(5,number)
  
 for i=0L,number-1,1 do begin
	j=where(struct.m(*,i) gt 0 and struct.m(*,i) lt 30)
	if ((size(j))(0) ne 0) then begin
	  if ((size(j))(1) gt 2) then begin
		k=moment(struct.m(j,i))
		output(0:3,i)=k
		output(4,i)=(size(j))(1)
	  endif else begin
		output(0,i)=-1.5
		output(1,i)=0.0
		output(4,i)=(size(j))(1)
	  endelse		
	endif else begin
		output(0,i)=-2.0
		output(1,i)=0.0
		output(4,i)=0
	endelse
 endfor
 return
 end
