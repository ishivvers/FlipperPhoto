pro get_prob_error,inx,inprob,bestx,pex,mex,doplot=doplot,over=over,xtitle=xtitle,gausserr=gausserr

x=linespace(min(inx),max(inx),10000)
prob=spline(inx,inprob,x)

maxprob=max(prob,wmax)
bestx=x[wmax]
prob=prob/total(prob)

for i=wmax+1,n_elements(x)-1 do begin
    w=where(prob ge prob[i],nw)
    if total(prob[w]) gt 0.68 then begin
        mex=bestx-x[min(w)]
        pex=x[max(w)]-bestx
        break
    endif
endfor

;; fit a gaussian
yfit=gaussfit(inx,inprob,a,est=[maxprob,bestx,(mex+pex)/2.0],nterms=3)
bestx=a[1]
gausserr=a[2]

if keyword_set(doplot) then begin
    col=getcolor(/load)
    if keyword_set(over) then oplot,x,prob/max(prob) $
    else plot,x,prob/max(prob),xtitle=xtitle,ytitle='Relative Probability',xs=3,yr=[0,1.1],ys=1
    oplot,inx,inprob/max(inprob),ps=4
    oplot,bestx-[1,1]*mex,!y.crange,linestyle=1
    oplot,[1,1]*pex+bestx,!y.crange,linestyle=1

    ;; show the gaussian fit
    y=a[0]*exp(-((x-a[1])/a[2])^2.0/2.0)
    oplot,x,y/max(y),col=col.green
endif

end
