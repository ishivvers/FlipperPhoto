FUNCTION display_type

  IF (!d.flags AND 1) EQ 0 THEN return,'X' ELSE return,'PS'

END
