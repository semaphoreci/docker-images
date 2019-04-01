#!/bin/bash

set -x

BUILD_DIR=$1

for dir in ${BUILD_DIR///}/*; do
  dockerfile=`basename $file`
  version=$(echo $dockerfile | awk -F"${BUILD_DIR///}-" '{print $2}')
  docker push semaphoreci/${BUILD_DIR///}:${version//-/.}
done
