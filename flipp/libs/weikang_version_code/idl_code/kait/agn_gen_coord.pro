pro agn_gen_coord,ra,dec,dssfits,cutedge=cutedge,rad=rad,magl=magl

if n_params() eq 0 then begin
  print,'syntax - agn_gen_coord,ra,dec,dssfits,cutedge=cutedge,rad=rad,magl=magl'
  return
endif

if not keyword_set(cutedge) then cutedge=30.0
if not keyword_set(rad) then rad=0.1
if not keyword_set(magl) then magl=19.0
;;dss image usually download with width of 10', namely radius 5'

usnoreadb,ra,dec,0.3,cat

head=headfits(dssfits)

extast,head,astr
naxis1=sxpar(head,'NAXIS1')
naxis2=sxpar(head,'NAXIS1')
maxxy=max(naxis1,naxis2)


ind=sort(cat.R2MAG)
cat=cat[ind]

gsssadxy,astr,cat.RAJ2000,cat.DEJ2000,x,y
ind=where(x ge cutedge and x le maxxy-cutedge and y ge cutedge and y le maxxy-cutedge and cat.R2MAG le magl)

goodcat=cat[ind]
goodx=x[ind]
goody=y[ind]

for i=0,n_elements(goodcat)-1 do begin
  print,goodx[i],goody[i],goodcat[i].R2MAG,goodcat[i].RAJ2000/double(15.0),goodcat[i].DEJ2000,format='(f9.2,f9.1,f7.2,f12.6,f12.5)'
endfor

end



