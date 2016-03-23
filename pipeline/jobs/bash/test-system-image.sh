#!/usr/bin/env bash -exl

if [[ -z ${tier} ]];
then
  echo tier must be defined
fi

if [[ ! -f create-system-image-results ]];
then
  create-system-image-results file not found
  exit 1
fi

source create-system-image-results

set +e
bundle --version
if [[ $? != 0 ]];
then
  gem install bundler --version 1.11.2
fi
set -e

bundle install

subnet_id=$(yaml_get pipeline/tier/${tier}.yml subnet_id)

cat <<END > input.yml
image_id: ${ami_id}
subnet_id: ${subnet_id}
END

# this region is the only game in town for
export AWS_REGION=us-west-2

stack_name=inspector-target-$(date +%s)
cfndsl_converge --stack-name ${stack_name} \
                --path-to-stack pipeline/cfndsl/inspector_target_cfndsl.rb \
                --path-to-yaml input.yml

# call run preview to make sure the instance is phoning home?

# hard code this until inspector API is in a better shape to retrieve artefacts by name
assessment_template_arn='arn:aws:inspector:us-west-2:592804526322:target/0-61RJmAmP/template/0-sH0ib1lk'
bash -ex inspector_provisioning/run-assessment.sh ${assessment_template_arn}

aws cloudformation delete-stack --stack-name ${stack_name} --region ${AWS_REGION}

# process findings
cat findings.json