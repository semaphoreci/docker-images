#!/bin/bash

set -x

for dir in */; do
  repo=`basename ${dir}`
  for file in $repo/*; do
    dockerfile=`basename $file`
    version=$(echo $dockerfile | awk -F"$repo-" '{print $2}')
    i=0
    docker build -t semaphoreci/$repo:${version//-/.} -f $file $dir || ((i++))
    time dgoss run -e DEBUG=true semaphoreci/$repo:${version//-/.} || ((i++))
    if [ $i > 0 ];then 
      #cat /goss/docker_output.log
      exit $i
    fi
    ls -lah
  done
done
