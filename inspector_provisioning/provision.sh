#!/bin/bash -ex

# oregon is the only game in town for Inspector
export AWS_REGION=us-west-2
aws configure add-model --service-model https://s3-us-west-2.amazonaws.com/inspector-service-model/inspector-2016-02-16.normal.json \
                        --service-name inspector

resource_group_arn_json=$(aws inspector create-resource-group --resource-group-tags key=target,value=inspector-amz-2015.09.02 \
                                                              --region ${AWS_REGION})

resource_group_arn=$(echo ${resource_group_arn_json} | jq '.resourceGroupArn' | tr -d '"')

assessment_target_name=amz_2015.09.02_hardening

#no apparent way to find out if the target is already there by name... so this is NOT idempotent
assessment_target_json=$(aws inspector create-assessment-target --assessment-target-name ${assessment_target_name} \
                                                                --resource-group-arn ${resource_group_arn} \
                                                                --region ${AWS_REGION})

assessment_target_arn=$(echo ${assessment_target_json} | jq '.assessmentTargetArn' | tr -d '"')

all_but_pci_dss_rules_packages_array=( \
  arn:aws:inspector:us-west-2:758058086616:rulespackage/0-Pv9mELS9 \
  arn:aws:inspector:us-west-2:758058086616:rulespackage/0-11B9DBXp \
  arn:aws:inspector:us-west-2:758058086616:rulespackage/0-X1KXtawP \
  arn:aws:inspector:us-west-2:758058086616:rulespackage/0-LzUxcT5A \
)

for rules_package in "${all_but_pci_dss_rules_packages_array[@]}";
do
  all_but_pci_dss_rules_packages="${all_but_pci_dss_rules_packages} ${rules_package}"
done

assessment_template_name=amz_2015.09.02_hardening
assessment_template_json=$(aws inspector create-assessment-template --assessment-template-name ${assessment_template_name} \
                                                                    --assessment-target-arn ${assessment_target_arn} \
                                                                    --duration-in-seconds $((15*60)) \
                                                                    --rules-package-arns ${all_but_pci_dss_rules_packages} \
                                                                    --region ${AWS_REGION})

assessment_template_arn=$(echo ${assessment_template_json} | jq '.assessmentTemplateArn' | tr -d '"')

echo ${assessment_template_arn} > assessment_template_arn