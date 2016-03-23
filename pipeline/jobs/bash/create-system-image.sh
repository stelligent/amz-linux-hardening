#!/usr/bin/env bash -exl
set -o pipefail

if [[ -z ${tier} ]];
then
  echo tier must be defined
fi

set +e
bundle --version
if [[ $? != 0 ]];
then
  gem install bundler --version 1.11.2
fi
set -e

bundle install

vpc_id=$(yaml_get pipeline/tier/${tier}.yml vpc_id)
subnet_id=$(yaml_get pipeline/tier/${tier}.yml subnet_id)
ami_name_stem=hardened_amz_linux_2015.09.02_

packer -machine-readable build \
    -var "vpc_id=${vpc_id}" \
    -var "subnet_id=${subnet_id}" \
    -var "ami_name=${ami_name_stem}$(date +%s)" \
    packer/base_amzn_linux_2015.09.02.json | tee build.log

ami_id=$(grep 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2)

echo ami_id=${ami_id} > create-system-image-results