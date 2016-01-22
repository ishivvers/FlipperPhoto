function get_fixrad,cobjnames,fwhm

if n_elements(fwhm) eq 0 then begin
    n=n_elements(cobjnames)
    fwhm=fltarr(n)
    print,n,format='(i5," files")'
    print,'working on...',format='(a,$)'
    for i=0,n-1 do begin
        if i mod 10 eq 0 then print,strtrim(i,2),format='(a,"...",$)'
        ;; read in the cobjfile
        cal=mrdfits(cobjnames[i],2,/silent)
        
        ;; see if the file read worked
        s=size(cal)
        type=s[s[0]+1]
        if type eq 2 then begin
            ;; file read failed, try again
            print,'GET_FIXRAD: Error reading cobjfile. Trying again...'
            wait,2
            cal=mrdfits(cobjnames[i],2,/silent)
            s=size(cal)
            type=s[s[0]+1]
            if type eq 2 then begin
                print,'!!!!!!!!!!!!!!!!!'
                print,'GET_FIXRAD: could not access cobjfile! Fix it.'
                print,'!!!!!!!!!!!!!!!!!'
                stop
            endif
        endif
        fwhm[i]=cal.fwhm
    endfor
endif else n=n_elements(fwhm)

;; set fixrad to 90% level
blah=fwhm[sort(fwhm)]
fixrad=round(blah[0.90*n]*10)/10.0

print,fixrad,format='("Fixrad is ",f6.2)'

min=floor(min(fwhm)*10)/10.0 - 0.25
max=ceil(max(fwhm)*10)/10.0 + 0.25
hist=histogram(fwhm,min=min,max=max,bin=0.05)
bins=linespace(min,max,n_elements(hist))
plot,bins,hist,ps=10
oplot,[1,1]*fixrad,!y.crange,linestyle=1

ans=''
read,ans,prompt='Fixrad OK (y/s): '
if ans eq 's' then stop

return,fixrad
end
