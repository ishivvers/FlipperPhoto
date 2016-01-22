#!/bin/sh
#This is the kait pipeline sh version

pipeline_dir=/kait/pipeline/

while [ 1 ]
do
  newfiles=`find $pipeline_dir  -name "*.Z"`
  
  sleep 10
  cd $pipeline_dir
  for file in $newfiles
  do
    #echo $file
    echo unziping file : $file
    gunzip -d $file
  done
  
  newfiles=`find $pipeline_dir  -name "*.fts" -o -name "*.grid" -o -name "*.fit" -o -name "*.fits" `
  cd $pipeline_dir
  for file in $newfiles
  do
    echo wording on file : $file
    cmd="kait_pipeline_image,'$file'"
    echo $cmd
    echo $cmd | nice idl
  done

#sleep for one minutes
echo "Sleeping for 60s ..."
sleep 60
done
