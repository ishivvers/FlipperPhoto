;IPN_FILTER
;
;NAME:  IPN_FILTER.PRO
;PURPOSE:  
;       Takes IPN arc given as center + radius (in degrees)
;       and finds which cobj objects are within it.
;
;CALLING SEQUENCE: 
;       CONVERT_IPN,rac,decc,rad,ipn
;INPUTS:
;       rac:  RA coord of center point of arc (in degrees).
; 
;       decc: DEC coord of center point of arc.
;
;       rad:  Radius of arc
;
;OUTPUTS:
;       ipn:  Structure containing the full ipn arc
;    
;REVISIONIST HISTORY:
;  	Andy Pawl;     UM;     CREATED  3/12/99
;	04-19-00:	Bob Kehoe -- reworked to output indices of
;				passing objects
;===============================================================

function ipn_filter, centr,rad,width,boxra,boxdec,catra,catdec

IF N_PARAMS() EQ 0 THEN BEGIN
  PRINT, 'syntax: ipn_filter,centr,rad,width,boxra,boxdec,catin,catout'
  RETURN,-1
ENDIF

rac = centr(0)
decc = centr(1)
decmax = decc + rad

boxra = boxra + 3.0

;print, 'rac, decc, decmax',rac,decc,decmax
;print, 'boxra',boxra
;print, 'boxdec',boxdec

;##find center & radius of circle in plane of intersection 
z0 = sin(!pi*decc/180.0)
x0 = cos(!pi*rac/180.0)*cos(!pi*decc/180.0)
y0 = sin(!pi*rac/180.0)*cos(!pi*decc/180.0)
vecc = [x0,y0,z0]*cos(!pi*rad/180.0)

;print, 'x0,y0,z0,vecc',x0,y0,z0,vecc

;##find bounding angles for the arc. To do so, we need a 
;   vector in the plane (damn it all)!
neg = where(boxra lt rac)
pos = where(boxra gt rac)

;if (neg[0] ne -1) then print, 'boxra neg',boxra[neg]
;if (pos[0] ne -1) then print, 'boxra pos',boxra[pos]

check = 'ra'
IF (neg(0) ne -1) and (pos(0) ne -1) then begin
  zvec = z0
  check = 'dec'
ENDIF ELSE BEGIN
  ;##generate maximum z value
  zvec = sin(!pi*decmax/180.0)
ENDELSE

print, 'neg,pos,check,zvec',neg,pos,check,zvec

;##find corresponding x, y
b = -2*(cos(!pi*rad/180.0)-z0*zvec)*x0/(y0^2)
a = (x0/y0)^2+1
c = zvec^2-1+(cos(!pi*rad/180.0)-z0*zvec)^2/y0^2
IF check eq 'ra' then begin
  xvec = -b / (2*a)
ENDIF ELSE BEGIN
;  xvec = (-b + sqrt(b^2-4*a*c))/(2*a)
  xvec = (-b - sqrt(b^2-4*a*c))/(2*a)
ENDELSE
yvec = (cos(!pi*rad/180.0)-x0*xvec - z0*zvec)/y0
vec = [xvec,yvec,zvec]-vecc

;print, 'a,b,c',a,b,c
;print, 'xv,yv,zv,vec',xvec,yvec,zvec,vec

;##now get xyz coords of the bounding box:
boxcoord = create_struct('xyz',fltarr(3))
boxcoord = replicate(boxcoord,4)
boxcoord.xyz(0) = cos(!pi*boxra/180.0)*cos(!pi*boxdec/180.0)
boxcoord.xyz(1) = sin(!pi*boxra/180.0)*cos(!pi*boxdec/180.0)
boxcoord.xyz(2) = sin(!pi*boxdec/180.0)

;print, 'boxcoord',boxcoord.xyz[0],boxcoord.xyz[1],boxcoord.xyz[2]

;##define angles
phi = fltarr(4)
FOR i = 0,3 DO BEGIN
  phi(i) = acos(total((boxcoord(i).xyz-vecc) * vec)$
	/(sqrt(total((boxcoord(i).xyz-vecc)^2)*total(vec^2))))
ENDFOR
hiphi = max(phi)
lowphi = min(phi)
;print, 'phis', phi
;print, 'hi, lo', hiphi, lowphi

radmin = cos(!pi*(rad+width)/180.0)
radmax = cos(!pi*(rad-width)/180.0)

;##now take care of the actual data!
N_Obj = long(n_elements(catra))
cat = create_struct('xyz',fltarr(3))
cat = replicate(cat,N_Obj)
cat.xyz(0) = cos(!pi*catra/180.0)*cos(!pi*catdec/180.0)
cat.xyz(1) = sin(!pi*catra/180.0)*cos(!pi*catdec/180.0)
cat.xyz(2) = sin(!pi*catdec/180.0)
gdbad = intarr(N_Obj)
FOR i = long(0), N_Obj-1 DO BEGIN
  phi = acos(total((cat(i).xyz-vecc)*vec)$
	/(sqrt(total((cat(i).xyz-vecc)^2)*total(vec^2))))
  catrad = total(cat(i).xyz * [x0,y0,z0])
  IF ((radmax ge catrad) and (catrad ge radmin))  then begin
    IF (hiphi ge phi) and (lowphi le phi) then begin
      IF check eq 'dec' THEN BEGIN
        if ((decc - boxdec(0))*(decc-catdec[i])) gt 0 then gdbad[i] = 1
      ENDIF ELSE BEGIN
        if ((rac - boxra(0))*(rac-catra[i])) gt 0 THEN gdbad[i] = 1
      ENDELSE
    ENDIF
  ENDIF
ENDFOR

;##dump the good stuff into the new catalog
  goodobj = where(gdbad eq 1)
  return, goodobj
END

