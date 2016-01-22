#!/bin/sh
#if [ $# -ne 4 -a $# -ne 5 ]
if [ $# -eq 0 ]
then
        echo "usage:command file(s)"
        exit 0
fi

conf_file=/rotse10/data0/products/FitHeaderFormat/default.conf
parameter=`cat $conf_file | sed '/#/d' | awk '{print $1}'`
value=`cat $conf_file | sed '/#/d' | awk '{print $2}'`
PAR=($parameter)
VAL=($value)

len=${#PAR[*]}
i=0
while [ $i -lt $len ]
do
 #if [ ${VAL[$i]} = NONE ]
 #then
 #  eval ${PAR[$i]}=''
 #else
 #  eval ${PAR[$i]}=${VAL[$i]}
 #fi
 eval ${PAR[$i]}=${VAL[$i]}
 let i++
done
#echo $DATE
#echo $TIME
#echo $EXPTIME
#echo $EFFTIME
#echo $PIXSCALE
#echo $RA_OBJ
#echo $DEC_OBJ

for file in $*
do
  echo processing file : $file
  truetime=`gethead $DATE $TIME $file`
  truemjd=`echo $truetime | sed 's/:/ /g' | sed 's/-/ /g' | sed 's/T/ /g' | sed 's=/= =g' | xargs -n 6 Mjd`
  #echo $truemjd

  #From now generate the sethead keyword and value
  setheadkeywork=""
  if [ $EXPTIME != NONE ]
  then
    trueexptime=`gethead $EXPTIME $file`
    setheadkeywork=`echo "$setheadkeywork EXPTIME=$trueexptime "`
    truemjd=`echo $truemjd $trueexptime | awk '{printf("%.6f",$1+$2/2/86400)}'`
  fi
  setheadkeywork=`echo "$setheadkeywork MJD=$truemjd "`
  if [ $EFFTIME != NONE ]
  then
    trueefftime=`gethead $EFFTIME $file`
    setheadkeywork=`echo "$setheadkeywork EFFTIME=$trueefftime "`
  else
    setheadkeywork=`echo "$setheadkeywork EFFTIME=0 "`
  fi
  if [ $PIXSCALE != NONE ]
  then
    #truepixscale=`gethead $PIXSCALE $file`
    truepixscale=$PIXSCALE
    setheadkeywork=`echo "$setheadkeywork PIXSCALE=$truepixscale"`
  fi
  if [ $RA_OBJ != NONE ]
  then
    truera_obj=$RA_OBJ
    setheadkeywork=`echo "$setheadkeywork RA_OBJ=$truera_obj"`
  fi
  if [ $DEC_OBJ != NONE ]
  then
    truedec_obj=$DEC_OBJ
    setheadkeywork=`echo "$setheadkeywork DEC_OBJ=$truedec_obj"`
  fi
  if [ $SATCNTS != NONE ]
  then
    truesatcnts=$SATCNTS
    setheadkeywork=`echo "$setheadkeywork SATCNTS=$truesatcnts"`
  fi
  if [ $BSTDDEV != NONE ]
  then
    truebstddev=$BSTDDEV
    setheadkeywork=`echo "$setheadkeywork BSTDDEV=$truebstddev"`
  else
    setheadkeywork=`echo "$setheadkeywork BSTDDEV=0"`
  fi


  cmd="sethead $setheadkeywork $file"

  echo $cmd
  $cmd
done
