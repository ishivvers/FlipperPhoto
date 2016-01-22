;; ********************************************************************************
pro powerlaw,x,a,f,pder

;; return the value of f=a[0]*x^a[1], calculate derivatives at x

f=a[0]*x^a[1]

;; derivatives
IF N_PARAMS() GE 4 THEN pder=[[x^a[1]],[a[0]*alog(x)*x^a[1]]]

end


;; ********************************************************************************
;; ********************************************************************************
pro fitalpha,tburst,etburst,flux,eflux,alpha,f0,minchisq,ealpha

;; set approximate value for f0
f0a=flux/tburst^(-1.0)
ef0a=eflux/tburst^(-1.0)
inf0=wtaverage(f0a,ef0a)
f0=inf0[0]

;; get the rough fit
a=[f0,-1.0]
yfit = CURVEFIT(tburst,flux,eflux^(-2.0),a,sigma,function_name='powerlaw',chisq=fitchisq)
f0=a[0]
alpha=a[1]
ef0=sigma[0]
ealpha=sigma[1]
print,f0,ef0,format='("curvefit f0=",f," +/- ",f)'
print,alpha,ealpha,format='("curvefit alpha=",f," +/- ",f)'

;; get the probability
print,'Calculating probability...'
nf0=300
f0s=logspace((f0-5*ef0 > 1),f0+5*ef0,nf0)
nalpha=300
alphas=linespace(alpha-5*ealpha,alpha+5*ealpha,nalpha)
alphaprob=fltarr(nalpha)
dof=n_elements(tburst)-1
chisq=fltarr(nf0,nalpha)
minchisq=1e99
for i=0,nf0-1 do begin
    for j=0,nalpha-1 do begin
        model=f0s[i]*tburst^alphas[j]
        cs=total((flux-model)^2.0/(eflux)^2.0)
        chisq[i,j]=cs
        prob=exp(-0.5*(cs))
        alphaprob[j]=alphaprob[j]+prob

        if cs lt minchisq then begin
            bestinds=[i,j]
            minchisq=cs
        endif
    endfor
endfor
print,''

get_prob_error,alphas,alphaprob,bestalpha,mealpha,pealpha,/doplot,xtitle='Alpha'
print,bestalpha,pealpha,mealpha,format='("Best alpha=",f6.3," +",f6.3," -",f6.3)'

ans=''
read,ans,prompt='Press Enter: '

end
