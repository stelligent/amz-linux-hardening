#!/usr/bin/env bash -ex

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

bundle install

subnet_id=$(yaml_get pipeline/tier/${tier}.yml subnet_id)

echo <<END > input.yml
image_id: ${ami_id}
subnet_id: ${subnet_id}
END

cfndsl_converge --stack-name inspector-target-$(date +%s) \
                --path-to-stack pipeline/cfndsl/inspector_target_cfndsl.rb \
                --path-to-yaml input.yml

# call run preview to make sure the instance is phoning home?

# hard code this until inspector API is in a better shape to retrieve artefacts by name
assessment_template_arn='arn:aws:inspector:us-west-2:592804526322:target/0-61RJmAmP/template/0-sH0ib1lk'
inspector_provisioning/run-assessment.sh ${assessment_template_arn}

# process findings
cat findings.json