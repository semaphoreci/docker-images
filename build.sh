#!/bin/bash

set -x
mkdir /tmp/tmp
cp $(which goss) /tmp/tmp/

BUILD_DIR=$1

verify()
{
  version=$2
  echo "" > /tmp/tmp/docker_output.log
  name=$1
  tag=""
  [[ "$3" ]] &&  name=${name}-$3 && tag="-$3"
  case ${name} in
    "ruby")
      sed "s|_ruby_version_|${version//-/.}|g" goss/goss_ruby.yaml > /tmp/tmp/goss.yaml ;;
    "ruby-node")
      sed "s|_ruby_version_|${version//-/.}|g" goss/goss_ruby-node.yaml > /tmp/tmp/goss.yaml ;;
    "android")
      cat goss/goss_android.yaml > /tmp/tmp/goss.yaml ;;
    "rust")
      sed "s|_rust_version_|${version//-/.}|g" goss/goss_rust.yaml > /tmp/tmp/goss.yaml ;;
    "haskell")
      sed "s|_ghc_version_|${version//-/.}|g" goss/goss_haskell.yaml > /tmp/tmp/goss.yaml ;;
    "ubuntu")
      sed "s|_ubuntu_version_|${version//-/.}|g" goss/goss_ubuntu.yaml > /tmp/tmp/goss.yaml ;;
    "python")
      sed "s|_python_version_|${version//-/.}|g" goss/goss_ubuntu.yaml > /tmp/tmp/goss.yaml ;;
  esac
  docker run -v /tmp/tmp:/goss semaphoreci/${BUILD_DIR///}:${version//-/.}${tag} sh -c 'cd /goss; ./goss validate' >/tmp/tmp/docker_output.log 2>/tmp/tmp/docker_output.log
  if ! grep -q 'Failed: 0' /tmp/tmp/docker_output.log; then
    echo 1
  else
    echo 0
  fi
}
for file in ${BUILD_DIR///}/*; do
  dockerfile=`basename $file`
  version=$(echo $dockerfile | awk -F"-${BUILD_DIR///}-" '{print $2}')
  tag=$(echo $dockerfile | awk -F"-${BUILD_DIR///}-" '{print $3}')
  image_tag=""
  [[ "$tag" ]] &&  image_tag="-$tag"
  docker build -t semaphoreci/${BUILD_DIR///}:${version//-/.}${image_tag} -f $file ${BUILD_DIR///}
  status=$(verify ${BUILD_DIR} ${version} ${tag})
  if [ $status == "1" ]; then
    cat /tmp/tmp/docker_output.log
    exit 1
  fi
    docker push semaphoreci/${BUILD_DIR///}:${version//-/.}${image_tag}
done
