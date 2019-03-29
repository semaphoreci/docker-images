#!/bin/bash

set -x
mkdir /tmp/tmp
for dir in */; do
  repo=`basename ${dir}`
  for file in $repo/*; do
    dockerfile=`basename $file`
    version=$(echo $dockerfile | awk -F"$repo-" '{print $2}')
    docker build -t semaphoreci/$repo:${version//-/.} -f $file $dir || ((i++))
    echo "" > /tmp/tmp/docker_output.log 
    cp $(which goss) /tmp/tmp/
    case $repo in
      "ruby")
          sed "s|_ruby_version_|$version" goss_ruby.yaml > /tmp/tmp.goss.yaml ;;
    esac
    docker run -v /tmp/tmp:/goss semaphoreci/$repo:${version//-/.} sh -c 'cd /goss; ./goss validate' >/tmp/tmp/docker_output.log 2>/tmp/tmp/docker_output.log
    dock=$?
    if (( $dock > 0 )); then 
      echo "Error:"
      cat /tmp/tmp/docker_output.log
      exit $dock
    fi
  done
done
