#!/bin/bash

set -x

for dir in */; do
  repo=`basename ${dir}`
  for file in $repo/*; do
    dockerfile=`basename $file`
    version=$(echo $dockerfile | awk -F"$repo-" '{print $2}')
    docker push semaphoreci/$repo:${version//-/.}
  done
done