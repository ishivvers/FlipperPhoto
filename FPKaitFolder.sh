#!/bin/bash
# This is a quick bash script that searches for all fits files within
#  the given input folder, assuming the normal KAIT naming scheme, and
#  runs flipphot on them.

if [ !  -z  ${1}  ] & [ ! -z ${2} ]; then
  echo "Input folder: ${1}";
  echo "Output folder: ${2}";
  
  for file in `find ${1} -regextype findutils-default -regex ".*\.fi?ts?\(\.Z\)?"`
  do
    echo $file
    flipprun -o ${2} $file
  done
else
  echo "Usage: ${0} [path/to/input/folder] [path/to/output/folder]"
fi

