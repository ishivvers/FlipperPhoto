pro rotse_setup


defsysv, '!rotse_setup', exists = exists
if exists eq 0 then begin
    defsysv,'!rotse_setup',1

    defsysv,'!usno_db_leaf_depth', 0
    defsysv,'!usno_leaf_depth', 7
    defsysv,'!match_leaf_depth', 9
    defsysv,'!match_db_leaf_depth', 2

    defsysv,'!usno_dbname','usno15'
    defsysv,'!tycho_dbname','tycho'
    defsysv,'!gsc_dbname','gsc1.2'

    defsysv,'!match_dbase_name', 'matchdb'
    defsysv,'!cobj_dbase_name', 'cobj_info'

    spawn,'hostname',host
    hostname=host[0]
    if ((strpos(hostname,'rotse2') ne -1) or (strpos(hostname,'rotse4') ne -1) or $
        (strpos(hostname,'rotse5') ne -1) or (strpos(hostname,'rotse6') ne -1) or (strpos(hostname,'abc1') ne -1)) then begin
;;        defsysv,'!usno_catdir','/rotse2/products/usno/'
;;        defsysv,'!sofile_path', '/rotse2/products/htmindexidl/bin'
        defsysv,'!match_archive_path','/rotse4/data2/rotse3/match/'
        defsysv,'!image_archive_path','/rotse4/data1/rotse3/'
        defsysv,'!usno_catdir','/products/usno/'
        defsysv,'!sofile_path','/products/htmindexidl/bin'
    endif else if (strpos(hostname,'physrykoff') ne -1) then begin
        defsysv,'!usno_catdir','/products/usno/'
        defsysv,'!sofile_path','/products/htmindexidl/bin'
        defsysv,'!match_archive_path','/home/erykoff/data/match/'
        defsysv,'!image_archive_path','/home/erykoff/data/'
    endif else begin
        defsysv,'!usno_catdir','/products/usno/'
        defsysv,'!sofile_path','/products/htmindexidl/bin'
        defsysv,'!match_archive_path','/rotse/data/rotse3/match/'
        defsysv,'!image_archive_path','/rotse/data/rotse3/'
    endelse
endif



return
end
