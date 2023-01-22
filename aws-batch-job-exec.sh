#!/bin/bash

# Check args
if [ $# != 3 ]; then
    echo "
-------------Usage-------------
bash ./aws-batch-job-exec.sh \\
fargate-resource-patter-lists.csv \\
arn:aws:batch:ap-northeast-1:123456789012:job-queue/measured-fargate-network-bandwidth-job-queue \\
arn:aws:batch:ap-northeast-1:123456789012:job-definition/measured-fargate-network-bandwidth-job-definition:3

===========Description===========
Arg1: Fargate resource pattern-lists
Arg2: Job queue arn (Refer to the output of \`terraform apply\`)
Arg3: Job definition arn (Refer to the output of \`terraform apply\`)

*********************************"
    exit 1
fi

JOB_ID=""

while IFS=, read VCPU MEMORY || [ -n "${VCPU}" ]; do
    echo "-Start submit job(CPU: ${VCPU}, MEMORY: ${MEMORY})"
    # first time
    if [ -z ${JOB_ID} ]; then
        JOB_RESPONSE=$(aws batch submit-job \
            --job-name "measured-network-bandwidth-vcpu-$(echo ${VCPU} | sed -e "s/\./_/")-memory-$(echo ${MEMORY} | sed -e "s/\./_/")" \
            --job-queue $2 \
            --job-definition $3 \
            --container-overrides "resourceRequirements=[{value=${VCPU},type=VCPU},{value=${MEMORY},type=MEMORY}]")
    # after the second time
    else
        JOB_RESPONSE=$(aws batch submit-job \
            --job-name "measured-network-bandwidth-vcpu-$(echo ${VCPU} | sed -e "s/\./_/")-memory-$(echo ${MEMORY} | sed -e "s/\./_/")" \
            --job-queue $2 \
            --job-definition $3 \
            --container-overrides "resourceRequirements=[{value=${VCPU},type=VCPU},{value=${MEMORY},type=MEMORY}]" \
            --depends-on "jobId=${JOB_ID},type=N_TO_N")
    fi
    JOB_ID=$(echo $JOB_RESPONSE | jq .jobId)
    echo "--Complete submit job(CPU: ${VCPU}, MEMORY: ${MEMORY})"
done <$1
