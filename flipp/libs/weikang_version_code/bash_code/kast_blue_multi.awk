#!/bin/gawk -f
BEGIN{
  factor=1.8558
}
{
  if ($0  ~ /^up/ || $0  ~ /^low/)
  {
    print $1 " " $2*factor
  }
  else if ($0  ~ /^samp/)
  {
    print $1 " " $2*factor " " $3*factor " " $4*factor " " $5*factor
  }
  else
  {
    print $0
  }
  #if ($0  ~ /^low/)
  #{
  #  print $1 " " $2*factor
  #}
}
