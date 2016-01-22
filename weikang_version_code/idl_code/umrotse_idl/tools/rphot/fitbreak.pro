;; ********************************************************************************
pro smoothbrokenpowerlaw,x,a,f,pder

;; a[0] = f0
;; a[1] = smoothness
;; a[2] = t_break
;; a[3] = alpha1
;; a[4] = alpha2


;; return the value of f=a[0]*s^(1/a[1])*[ (x/a[2])^(-a[1]*a[3]) + (x/a[2])^(-a[1]*a[4]) ]^(-1/a[1])
;; calculate derivatives at x

f=a[0]*2.0^(1/a[1])*[ (x/a[2])^(-a[1]*a[3]) + (x/a[2])^(-a[1]*a[4]) ]^(-1/a[1])

;; derivatives
IF N_PARAMS() GE 4 THEN pder=[0] ;; ### write this ###

end


;; ********************************************************************************
pro brokenpowerlaw,x,a,f,pder

common brokenpowerlaw_prams,smooth

;; a[0] = f0
;; a[1] = t_break
;; a[2] = alpha1
;; a[3] = alpha2

;; return the value of f=a[0]*s^(1/smooth)*[ (x/a[1])^(-smooth*a[2]) + (x/a[1])^(-smooth*a[3]) ]^(-1/smooth)
;; calculate derivatives at x

f=a[0]*2.0^(1.0/smooth)*[ (x/a[1])^(-smooth*a[2]) + (x/a[1])^(-smooth*a[3]) ]^(-1.0/smooth)

;; derivatives
IF N_PARAMS() GE 4 THEN pder=[0] ;; ### write this ###

end

;; ********************************************************************************
;; ********************************************************************************
pro fitbreak,tburst,etburst,flux,eflux,f0,outsmooth,tb,alpha1,alpha2,ealpha1,ealpha2,etb,chisqfit

common brokenpowerlaw_prams,smooth

if not keyword_set(smooth) then smooth=20.0

;; set approximate value for f0
f0a=flux/tburst^(-1.0)
ef0a=eflux/tburst^(-1.0)
inf0=wtaverage(f0a,ef0a)
tb=400.0
f0=inf0[0]*tb^(-1.0)

;; get the rough fit
a=[f0,tb,-0.35,-.85]
yfit = CURVEFIT(tburst,flux,eflux^(-2),a,sigma,function_name='brokenpowerlaw',chisq=chisqfit,/noder)
;;a=[1500.0,smooth,400.0,-0.35,-.85]
;;yfit = CURVEFIT(tburst,flux,eflux^(-2),a,sigma,function_name='smoothbrokenpowerlaw',chisq=chisqfit,/noder)

f0=a[0]
tb=a[1]
alpha1=a[2]
alpha2=a[3]
ef0=sigma[0]
etb=sigma[1]
ealpha1=sigma[2]
ealpha2=sigma[3]
outsmooth=smooth

;; force alpha2 to be steeper
if alpha1 lt alpha2 then begin
    tempa1=alpha1
    tempea1=ealpha1
    alpha1=alpha2
    ealpha1=ealpha2
    alpha2=tempa1
    ealpha2=tempea1
endif

print,'Curvefit results:'
print,f0,ef0,format='("  f0=",f," +/- ",f)'
print,tb,etb,format='("  tb=",f," +/- ",f)'
print,alpha1,ealpha1,format='("  alpha1=",f," +/- ",f)'
print,alpha2,ealpha2,format='("  alpha2=",f," +/- ",f)'
print,chisqfit,format='("  Chisq/dof=",f)'

ans=''
read,ans,prompt='Calculate probability surface (very slow) y/n? '
if ans ne 'y' then return

;; get the probabilities
nf0=100
ntb=100
nalpha1=100
nalpha2=100
if nf0 eq 1 then f0s=f0 $
else f0s=logspace(f0-5*ef0,f0+5*ef0,nf0)
tbs=logspace((tb-5*etb > min(tburst)),(tb+5*etb < max(tburst)),ntb)
alpha1s=linespace(alpha1-5*ealpha1,alpha1+5*ealpha1,nalpha1)
alpha2s=linespace(alpha2-5*ealpha2,alpha2+5*ealpha2,nalpha2)
f0prob=fltarr(nf0)
tbprob=fltarr(ntb)
alpha1prob=fltarr(nalpha1)
alpha2prob=fltarr(nalpha2)
print,'running ',ntb
for j=0,ntb-1 do begin
    print,j,format='(i,"...",$)'
    for i=0,nf0-1 do begin
        for k=0,nalpha1-1 do begin
            for l=0,nalpha2-1 do begin
                model=f0s[i]*2.0^(1/smooth)*[ (tburst/tbs[j])^(-smooth*alpha1s[k]) + (tburst/tbs[j])^(-smooth*alpha2s[l]) ]^(-1/smooth)
                chisq=total((flux-model)^2.0/(eflux)^2.0)
                
                if finite(chisq) eq 1 then begin
                    prob=exp(-0.5*chisq)
                    f0prob[i]=f0prob[i]+prob
                    tbprob[j]=tbprob[j]+prob
                    alpha1prob[k]=alpha1prob[k]+prob
                    alpha2prob[l]=alpha2prob[l]+prob
                endif
            endfor
        endfor
    endfor
endfor
print,''

!p.multi=[0,2,2]
get_prob_error,alpha1s,alpha1prob,bestalpha1,mealpha1,pealpha1,/doplot,xtitle='alpha1',gausserr=gealpha1
print,bestalpha1,mealpha1,pealpha1,gealpha1,format='("Best alpha1=",f6.3," +",f6.3," -",f6.3," (+/- ",f6.3,")")'
get_prob_error,alpha2s,alpha2prob,bestalpha2,mealpha2,pealpha2,/doplot,xtitle='alpha2',gausserr=gealpha2
print,bestalpha2,mealpha2,pealpha2,gealpha2,format='("Best alpha2=",f6.3," +",f6.3," -",f6.3," (+/- ",f6.3,")")'
!p.multi=[1,1,2]
get_prob_error,tbs,tbprob,besttb,metb,petb,/doplot,xtitle='tbreak',gausserr=getb
print,besttb,metb,petb,getb,format='("Best tbreak=",f8.2," +",f6.2," -",f6.2," (+/- ",f6.2,")")'
!p.multi=0

ans=''
read,ans,prompt='Press Enter: '

end
