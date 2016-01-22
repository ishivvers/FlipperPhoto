pro user_settings, datestr=datestr,mjd=mjd,exptime=exptime,readtime=readtime,$
		ncoadds=ncoadds,mlim=mlim,mlimco=mlimco,rac=rac,decc=decc,$
		fov=fov,nsingles=nsingles,peak=peak,indices=indices,baseline=baseline,$
		per1=per1,ampl1=ampl1,naxis1=naxis1,naxis2=naxis2,help=help
;+
; NAME: User Settings
;
; PURPOSE:
;	Permit user-defined settings for lightcurve simulation.
;
; CALLING SEQUENCE:
;       user_settings, datestr=datestr,mjd=mjd,exptime=exptime,readtime=readtime,
;		ncoadds=ncoadds,mlim=mlim,mlimco=mlimco,rac=rac,decc=decc,
;		fov=fov,nsingles=nsingles,peak=peak,indices=indices,baseline=baseline,
;		per1=per1,ampl1=ampl1,naxis1=naxis1,naxis2=naxis2,help=help
;
; Keywords:
;	datestr:	first day we took ROTSE-I images
;	mjd:		modified julian date for above
;	exptime:	exposure time in single exposure
;	readtime:	read-out time
;	ncoadds:	# images co-added in longer exposures
;	mlim:		sensitivity of single image
;	mlimco:		sensitivity of co-added images
;	rac:		central RA (deg)
;	decc:		dentral Dec (deg)
;	fov:		field-of-view (deg)
;	peak:		peak magnitude range
;	indices:	power-law index range
;	baseline:	steady-state magnitude
;	per1:		most prominent period
;	ampl1:		amplitude of variation for most prominent frequency
;	nsingles:	# exposures taken during each tiling
;	naxis1:		X size of image
;	naxis2:		Y size of image
;	help:		print a helpful comment
;
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if keyword_set(help) then begin
    print, 'Syntax:  user_settings,datestr=datestr,mjd=mjd,exptime=exptime,readtime=readtime,ncoadds=ncoadds,mlim=mlim,rac=rac,decc=decc,fov=fov,nsingles=nsingles,peak=peak,indices=indices,naxis1=naxis1,naxis2=naxis2,baseline=baseline,per1=per1,ampl1=ampl1,help=help'
    return
 endif

; Date stuff

 datestr = '970731'
 mjd = julday(7,31,1997) - 2400000.5

; Exposure stuff

 exptime = 80.0
 readtime = 7.5
 ncoadds = 2
 mlim = 15.3
 mlimco = mlim + sqrt(ncoadds) - 1.0

; Position
 
 rac = 180.0
 decc = 0.0
 fov = 8.0
 naxis1 = 2035
 naxis2 = 2069

; exposure sequence

 nsingles = 5

; power law ranges

 peak = [5.0, 15.0]
 indices = [-3.0, 0.0]
 baseline = [10.0, 17.0]
 per1 = [0.02, 0.5]
 ampl1 = [0.02, 0.5]

 return
end


