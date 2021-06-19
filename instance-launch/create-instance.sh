#!/bin/bash

sudo yum install gettext -y &>/dev/null

component=$1

if [ "${component}" == "all" ]; then
  for component in frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment; do
    echo "Creating ${component} Server"
    STATE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query Reservations[*].Instances[*].[State.Name] --output text)
    if [ "$STATE" != "running" ]; then
    aws ec2 run-instances --launch-template LaunchTemplateId=lt-00737ccd643dcd705 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${component}}]" &>/tmp/${component}.log
    sleep 30
    fi
    IPADDRESS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    export component
    export IPADDRESS
    envsubst <record.json >/tmp/"${component}".json
    aws route53 change-resource-record-sets --hosted-zone-id Z06632521MY6X8844QA0Y --change-batch file:///tmp/"${component}".json
    sed -i -e "/${component}/ d" ../inventory
    PUBLIC_IPADDRESS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    echo "${PUBLIC_IPADDRESS} APP=${component}" >>../inventory
  done
  exit
fi

if [ -z "${component}" ]; then
  echo "Provide Input of component name"
  exit 1
fi
STATE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query Reservations[*].Instances[*].[State.Name] --output text)

if [ "$STATE" != "running" ]; then
  aws ec2 run-instances --launch-template LaunchTemplateId=lt-00737ccd643dcd705 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${component}}]"
  sleep 30
fi
IPADDRESS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
export component
export IPADDRESS
envsubst <record.json >/tmp/"${component}".json
aws route53 change-resource-record-sets --hosted-zone-id Z06632521MY6X8844QA0Y --change-batch file:///tmp/"${component}".json
sed -i -e "/${component}/ d" ../inventory
PUBLIC_IPADDRESS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${component}" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
echo "${PUBLIC_IPADDRESS} APP=${component}" >>../inventory



