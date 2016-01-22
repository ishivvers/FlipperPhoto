pro coadd_and_process,fname_arr

if n_params() eq 0 then begin
    print,'syntax- coadd_and_process,fname_arr'
    return
endif

basedir = "/rotse/data/pipeline/"
linkdir = "/rotse/data/3?1/links/"

coadd_names3,fname_arr,minperc=0,coaddname=coaddname

cmd = "chmod 666 " + coaddname
spawn,cmd
cmd = "mv " + coaddname + " " + basedir + "image/"
spawn,cmd
cmd = "ln -s " + basedir + "image/" + coaddname + " " + linkdir
spawn,cmd


return
end
