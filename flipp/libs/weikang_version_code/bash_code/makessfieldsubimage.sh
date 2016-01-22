#!/bin/sh
#b [startvalue endvalue]
if [ $# -ne 4 -a $# -ne 5 ]
then
        echo "usage:command path field Ra Dec [radius(pixel)]"
        exit 0
fi
SEARCHPATH=$1
FIELD=$2
RA=$3
DEC=$4
if [ $# -eq 5 ]
then
        RAD=$4
else 
	RAD=120
fi

find $SEARCHPATH* -name "*$FIELD*000-000*" -exec cp {} . \;
find /rotse/data/sspipeline -name "*$FIELD*000-000*" -exec cp {} . \;
find /rotse/data/sspipeline/reference/ -name "*$FIELD*[0-9][0-9][0-9]_c*.fit*" -exec cp {} . \;
mkdir image
mkdir prod
mv *_c.fit* image
mv *.fit prod
echo makeallcobjsub,$RA,$DEC,$RAD | nice idl
#if [ ! -e "./ssfieldsubtmpdir" ]
#then 
#	mkdir ./ssfieldsubtmpdir
#fi
#cd ./ssfieldsubtmpdir
#for FILE in `find ../ -name "*$1*cobj.fit"`
#do
#	echo make_rotse3_subimage,\'$FILE\',racent=$RA,deccent=$DEC,pixrad=$RAD | nice idl
#done
echo "scp *$2*.fit zwk@rotse2:~/sstest/"
#scp *$1*.fit zwk@rotse2:~/sstest/
#rm -f *$1*.fit
