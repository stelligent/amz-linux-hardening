#!/usr/local/bin/bash -ex

#externalise me
region=us-west-2
tier=dev

bundle install --frozen

base_stack_name="CentOS-Hardened-AMI-Pipeline-${tier^^}"

set +e
aws cloudformation describe-stacks --stack-name ${base_stack_name} \
                                   --region ${region}
describe_stack_result=$?
set -e

cfndsl -y pipeline/tier/${tier}.yml pipeline/pipeline_cfndsl.rb > output.json

aws cloudformation validate-template --template-body file://output.json

if [[ ${describe_stack_result} == 0 ]];
then
  set +e
  aws cloudformation update-stack  --stack-name ${base_stack_name} \
                                   --template-body file://output.json \
                                   --region ${region} \
                                   --capabilities CAPABILITY_IAM
  set -e
else
  aws cloudformation create-stack  --stack-name ${base_stack_name} \
                                   --template-body file://output.json \
                                   --region ${region} \
                                   --capabilities CAPABILITY_IAM
fi