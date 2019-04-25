#!/bin/bash

set -x
mkdir /tmp/tmp
cp $(which goss) /tmp/tmp/

BUILD_DIR=$1

verify()
{
  echo "" > /tmp/tmp/docker_output.log 
  case $1 in
    "ruby")
      sed "s|_ruby_version_|${version//-/.}|g" goss/goss_ruby.yaml > /tmp/tmp/goss.yaml ;;
    "android")
      cat goss/goss_android.yaml > /tmp/tmp/goss.yaml ;;
    esac
    docker run -v /tmp/tmp:/goss semaphoreci/${BUILD_DIR///}:${version//-/.} sh -c 'cd /goss; ./goss validate' >/tmp/tmp/docker_output.log 2>/tmp/tmp/docker_output.log
  if ! grep -q 'Failed: 0' /tmp/tmp/docker_output.log; then
    echo 1
  else
    echo 0
  fi
}

for file in ${BUILD_DIR///}/*; do
  dockerfile=`basename $file`
  version=$(echo $dockerfile | awk -F"${BUILD_DIR///}-" '{print $2}')
  docker build -t semaphoreci/${BUILD_DIR///}:${version//-/.} -f $file ${BUILD_DIR///}
  status=$(verify $BUILD_DIR)
  if [ $status == "1" ]; then 
    cat /tmp/tmp/docker_output.log
    exit 1
  fi
    docker push semaphoreci/${BUILD_DIR///}:${version//-/.}
done
