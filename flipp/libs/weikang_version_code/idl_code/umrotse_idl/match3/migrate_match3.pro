pro migrate_match3,matchname,nmt,save=save

if n_params() lt 1 then begin
    print,'syntax- migrate_match3,matchname,nmt,save=save'
    print,' does not work with relmat structures yet'
    return
endif

mt=mrdfits(matchname,1)
st=mrdfits(matchname,2)

if (tag_exist(mt,'NOBS')) then begin
    print,matchname + ' is already a new-style match structure.'
    return
endif

nobj = n_elements(mt.ra)
nobs = n_elements(mt.jd)

make_match3_new,mt,nobs,nobj,/useold,/migrate

;; and save it

if keyword_set(save) then begin
    save_match,mt,st,/over
endif


nmt=mt

return
end
