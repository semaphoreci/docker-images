#!/bin/bash

set -x

BUILD_DIR=$1

for file in ${BUILD_DIR///}/*; do
  dockerfile=`basename $file`
  version=$(echo $dockerfile | awk -F"${BUILD_DIR///}-" '{print $2}')
  docker build -t semaphoreci/${BUILD_DIR///}:${version//-/.} -f $file ${BUILD_DIR///}
  docker push semaphoreci/${BUILD_DIR///}:${version//-/.}
done
