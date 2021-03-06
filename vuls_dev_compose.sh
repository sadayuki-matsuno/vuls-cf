#!/bin/bash
set -e

######################################################
# Argument Check
######################################################

function help_arg() {
  cat <<- EOS

sh vuls_dev_compose.sh [METHOD]
  METHOD :
      create
      delete

EOS
  exit 1
}

[ $# -gt 0 ] && [ $# -lt 3 ] || { echo "One argument is permitted"; help_arg; }
if [ $1 == "create" ]; then
  METHOD=create
elif [ $1 == "delete" ]; then
  METHOD=delete
else
  echo "Wrong arguments supplied"; help_arg
fi

######################################################
# Command Check
######################################################

function help_cmd() {
  cat <<- EOS

install blow command
  awscli
  jq 

EOS
  exit 1
}

which jq > /dev/null || { echo "Need to install jq"; help_cmd; }
which aws > /dev/null || { echo "Need to install aws"; help_cmd; }



######################################################
# Parameter Check
## You shoud set blow parameters at env
######################################################
CURRENT_DIR=$(cd $(dirname $0);pwd)
STACK_NAME_INSTTTANCES=vuls-dev-instances
STACK_NAME_OPSWORKS=vuls-dev-opsworks

function help_param() {
  cat <<- EOS

set blow parameters at your env
  VULS_VPC_ID:     vpc id (ex. vpc-11111111)
  VULS_REGION:     region (ex. ap-northeast-1)
  VULS_AZ:         availability zone (ex. ap-northeast-1a)
  VULS_SG_ID:      security group id (ex. sg-xxxxxx)
  VULS_KEY_NAME:   ssh key name (ex. vuls-dev)

EOS

  echo "-------------------VPC--------------------------"
  aws ec2  describe-vpcs | jq '.Vpcs | map({VpcId, CidrBlock, Tags}) '
  echo "--------------Security Group--------------------"
  aws ec2 describe-security-groups | jq ".SecurityGroups | map({Key: .GroupName , Value: .GroupId}) | from_entries"
  echo "-----------------Key Name-----------------------"
  aws ec2 describe-key-pairs | jq '.KeyPairs | map({KeyName})'

  exit 1
}

if [ $METHOD == "create" ]; then
  [ -z "$VULS_VPC_ID" ] && { echo "Need to set VULS_VPC_ID"; help_param; }
  [ -z "$VULS_REGION" ] && { echo "Need to set VULS_REGION"; help_param; }
  [ -z "$VULS_AZ" ] && { echo "Need to set VULS_AZ"; help_param; }
  [ -z "$VULS_SG_ID" ] && { echo "Need to set VULS_SG_ID"; help_param; }
  [ -z "$VULS_KEY_NAME" ] && { echo "Need to set VULS_KEY_NAME"; help_param; }
  [ -z "$VULS_PURPOSE" ] && { echo "Need to set VULS_PURPOSE"; help_param; }
fi


######################################################
# Create Instaces
######################################################
echo $METHOD  $TARGET
if [ $METHOD == "create" ]; then
  aws cloudformation create-stack \
     --stack-name vuls-dev-instances \
     --template-body "file:///${CURRENT_DIR}/vuls-dev-create-instances.template" \
     --region ${VULS_REGION} \
     --parameters \
  	ParameterKey=VPC,ParameterValue=${VULS_VPC_ID} \
  	ParameterKey=AZ,ParameterValue=${VULS_AZ} \
  	ParameterKey=SecurityGroupID,ParameterValue=${VULS_SG_ID} \
  	ParameterKey=Keyname,ParameterValue=${VULS_KEY_NAME} \
  	ParameterKey=VulsScanServerIP,ParameterValue=${VULS_SCANNER_IP} \
  
  aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME_INSTTTANCES}

  INSTANCES_IP=$(aws cloudformation describe-stacks --stack-name vuls-dev-instances)
  AMAZON_IP=$(echo $INSTANCES_IP | jq -r '.Stacks[].Outputs[] | select(.OutputKey == "AmazonPublicIP") | .OutputValue')
  UBUNTU_IP=$(echo $INSTANCES_IP | jq -r '.Stacks[].Outputs[] | select(.OutputKey == "UbuntuPublicIP") | .OutputValue')
  CENTOS_IP=$(echo $INSTANCES_IP | jq -r '.Stacks[].Outputs[] | select(.OutputKey == "CentOSPublicIP") | .OutputValue')
  REDHAT_IP=$(echo $INSTANCES_IP | jq -r '.Stacks[].Outputs[] | select(.OutputKey == "RedHatPublicIP") | .OutputValue')

  echo AMAZON_IP : $AMAZON_IP
  echo UBUNTU_IP : $UBUNTU_IP
  echo CENTOS_IP : $CENTOS_IP
  echo REDHAT_IP : $REDHAT_IP

  cat << EOS > config.toml

[default]
user        = "ec2-user"
port        = "22"
keyPath     = "/root/.ssh/$VULS_KEY_NAME.pem"

[servers]

[servers.amazon]
host        = "$AMAZON_IP"
user        = "ec2-user"

[servers.ubuntu]
host        = "$UBUNTU_IP"
user        = "ubuntu"

[servers.centos]
host        = "$CENTOS_IP"
user        = "centos"

[servers.redhat]
host        = "$REDHAT_IP"
user        = "ec2-user"
EOS
  exit 0
fi 


if [ $METHOD == "delete" ]; then
  aws cloudformation delete-stack --stack-name ${STACK_NAME_INSTTTANCES}
  echo "deleting ${STACK_NAME_INSTTTANCES}"
  aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME_INSTTTANCES}
  echo "vuls cloudformation is all deleted successfully"
  exit 0
fi
