PRO calc_phases, iel, elem, itz, mjd
  IF iel[elem].tzero EQ 0.0 THEN iel[elem].tzero = mjd[itz]
  
  FOR i=0,n_elements(mjd)-1 DO BEGIN 
      IF iel[elem].freq GT 0.0 THEN BEGIN 
          iel[elem].n[i] = floor((mjd[i] - iel[elem].tzero)*iel[elem].freq)
          iel[elem].phase[i] = (mjd[i] - iel[elem].tzero)*iel[elem].freq - iel[elem].n[i]
      ENDIF 
  ENDFOR 
END 
