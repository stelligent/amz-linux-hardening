#!/usr/bin/env bash -ex

assessment_template_arn=$1

findings_output_filename=findings.json

# oregon is the only game in town for Inspector
export AWS_REGION=us-west-2

assessment_run_name=amz-2015.09.02-hardening-$(date +%s)

assessment_run_json=$(aws inspector start-assessment-run --assessment-template-arn ${assessment_template_arn} \
                                                         --assessment-run-name ${assessment_run_name} \
                                                         --region ${AWS_REGION})

assessment_run_arn=$(echo ${assessment_run_json} | jq '.assessmentRunArn' | tr -d '"')

completed_at=null
while [[ ${completed_at} == null ]];
do
  assessment_run_status=$(aws inspector describe-assessment-runs --assessment-run-arns ${assessment_run_arn} \
                                                                 --region ${AWS_REGION})

  completed_at=$(echo ${assessment_run_status} | jq '.assessmentRuns[].completedAt')

  sleep 60
done

finding_arns=$(aws inspector list-findings --region ${AWS_REGION} | jq '.findingArns[]' | tr -d '"')

rm findings_tmp || true
for finding_arn in ${finding_arns};
do
  finding=$(aws inspector describe-findings --finding-arns ${finding_arn} \
                                            --region ${AWS_REGION})
  finding_assessment_run_arn=$(echo ${finding} | jq '.findings[].serviceAttributes.assessmentRunArn' | tr -d '"')

  if [[ ${finding_assessment_run_arn} == ${assessment_run_arn} ]];
  then
    echo ${finding} | jq 'to_entries + [{key: "finding_arn", value: "'${finding_arn}'"}]|from_entries' >> findings_tmp
  fi
done

cat findings_tmp | jq --slurp '' > ${findings_output_filename}