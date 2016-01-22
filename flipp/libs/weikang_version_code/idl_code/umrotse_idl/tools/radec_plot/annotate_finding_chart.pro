pro annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,mjd, $
                           rotate=rotate,box=box, compactlabel=compactlabel, $
                           putfname=putfname, imagename=imagename, dim=dim

if n_params() eq 0 then begin
    print,'syntax- annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,rotate=rotate,putfname=putfname,imagename=imagename,compactlabel=compactlabel'
    return
endif

if ((n_elements(rotate) eq 0) or (rotate ne 1)) then begin
    print,'currently only rotate=1 supported'
    return
endif

big_image = 1
if (n_elements(dim) eq 2) then begin
    if (dim[0] le 500) then big_image = 0
endif

xyouts,lims[0],lims[3]+5,'MJD = '+string(mjd,format='(f13.7)'),/data


if keyword_set(putfname) and n_elements(imagename) gt 0 then begin
    xyouts,(lims[1]+lims[0])/2.,lims[3]+20,imagename,alignment=0.5
endif else begin
    radecstr = '('+!tsym.alpha+','+!tsym.delta+'): '+string(ra,format='(f9.5)')+','+ $
               string(dec,format='(f9.5)')

    xyouts,(lims[1]+lims[0])/2.,lims[3]+25,radecstr,/data
endelse

if keyword_set(compactlabel) then begin
    xpos=lims[0]
    ypos=lims[3]+10.
endif else begin
    xpos=(lims[1]+lims[0])/2.
    ypos=lims[3]+5.
endelse

xyouts,xpos,ypos,'('+!tsym.alpha+','+!tsym.delta+'): '+ $
      radectostring(ra/15.0)+','+radectostring(dec,sign=1),/data


ral = skylims[0]*(3600./15.)
rah = skylims[1]*(3600./15.)
decl= skylims[2]*3600.
dech= skylims[3]*3600.

axis,yrange=[decl,dech],ystyle=1,yaxis=0,ytickname=[' ',' ',' ',' ',' ',' ',' ',' '],ytick_get=vy
axis,xrange=[rah,ral],xstyle=1,xaxis=0,xtickname=[' ',' ',' ',' ',' ',' ',' ',' '],xtick_get=vx


ynames=replicate(' ',n_elements(vy))
xnames=replicate(' ',n_elements(vx))
if (big_image) then begin
    for i=0,n_elements(xnames)-1 do begin
        xnames[i] = radectostring(vx[i]/3600.)
    endfor
endif else begin
    xnames[0] = radectostring(vx[0]/3600.)
    xnames[n_elements(xnames)-1] = radectostring(vx[n_elements(vx)-1]/3600.)
endelse

for i=0,n_elements(ynames)-1 do begin
    ynames[i] = radectostring(vy[i]/3600.,sign=1)
endfor

axis,yrange=[decl,dech],ystyle=1,yaxis=0,ytitle='Dec',ytickname=ynames
axis,xrange=[rah,ral],xstyle=1,xaxis=0,xtitle='RA',xtickname=xnames

return
end
