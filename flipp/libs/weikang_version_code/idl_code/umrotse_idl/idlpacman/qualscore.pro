function qualscore,st

if n_params() eq 0 then begin
    print,'syntax- qualscore, st'
    return,-1
endif

sexsig = st.sexbkdev
skysig = stddev(st.sky)

qscore = (skysig^2.)/(sexsig^2.)

qscore = 1.0

return,qscore
end
