#!/bin/sh
#b [startvalue endvalue]
#if [ $# -ne 1 -a $# -ne 5 ]
if [ $# -ne 1 ]
then
        echo "usage:command DataFileName"
        exit 0
fi
FileName=$1
awk 'BEGIN{print "#Tstart(s) Tstop(s)  Mag -err +err M_lim"} {printf("%.1f  %.1f  %.2f  %.2f  %.2f  %.2f\n",$1-$2,$1+$2,$3,$4-$3,$5-$3,$6)}' $FileName  | column -t
