#!/bin/bash
set -e

######################################################
# Argument Check
######################################################

function help_arg() {
  cat <<- EOS

sh vuls_dev_compose.sh [METHOD] [option]
  METHOD :
      create [all/instances/scanner]
      delete

EOS
  exit 1
}

[ $# -gt 0 ] && [ $# -lt 3 ] || { echo "One argument is permitted"; help_arg; }
if [ $1 == "create" ]; then
  if [ $2 == "all" ]; then
    METHOD=create
    TARGET=all
  elif [ $2 == "instances" ]; then
    METHOD=create
    TARGET=instances

  elif [ $2 == "scanner" ]; then
    METHOD=create
    TARGET=scanner
  else
    echo "Wrong arguments supplied"; help_arg
  fi
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
  VULS_KEY_NAME:   ssh key name (ex. vuls-dev)
  VULS_PURPOSE:    default or unsecure (ex. default)

EOS

  aws ec2  describe-vpcs

  exit 1
}

if [ $METHOD == "create" ]; then
  [ -z "$VULS_VPC_ID" ] && { echo "Need to set VULS_VPC_ID"; help_param; }
  [ -z "$VULS_REGION" ] && { echo "Need to set VULS_REGION"; help_param; }
  [ -z "$VULS_AZ" ] && { echo "Need to set VULS_AZ"; help_param; }
  [ -z "$VULS_KEY_NAME" ] && { echo "Need to set VULS_KEY_NAME"; help_param; }
  [ -z "$VULS_PURPOSE" ] && { echo "Need to set VULS_PURPOSE"; help_param; }
fi


######################################################
# Create Instaces
######################################################
echo $METHOD  $TARGET

if [ $METHOD == "create" ]; then

  if [ $TARGET == "all" ] || [ $TARGET == "scanner" ]; then
    aws cloudformation create-stack \
       --stack-name vuls-dev-opsworks \
       --template-body "file:///${CURRENT_DIR}/vuls-dev-create-opsworks.template" \
       --region ${VULS_REGION} \
       --capabilities CAPABILITY_IAM \
       --parameters \
    	ParameterKey=VPC,ParameterValue=${VULS_VPC_ID} 
    
    aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME_OPSWORKS}

    OPSWORKS_INSTANCE_ID=$(aws cloudformation describe-stacks --stack-name vuls-dev-opsworks | jq -r ".Stacks[].Outputs[2].OutputValue")
    VULS_SCANNER_IP=$(aws opsworks describe-instances --region us-east-1 --instance-ids ${OPSWORKS_INSTANCE_ID} | jq -r ".Instances[0].PublicIp")
  fi 

  if [ $TARGET == "all" ] || [ $TARGET == "instances" ]; then
    aws cloudformation create-stack \
       --stack-name vuls-dev-instances \
       --template-body "file:///${CURRENT_DIR}/vuls-dev-create-instances.template" \
       --region ${VULS_REGION} \
       --parameters \
    	ParameterKey=VPC,ParameterValue=${VULS_VPC_ID} \
    	ParameterKey=AZ,ParameterValue=${VULS_AZ} \
    	ParameterKey=Keyname,ParameterValue=${VULS_KEY_NAME} \
    	ParameterKey=VulsScanServerIP,ParameterValue=${VULS_SCANNER_IP} \
    	ParameterKey=Purpose,ParameterValue=unsecure
    
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

    [servers]

    [servers.amazon]
    host        = "$AMAZON_IP"
    port        = "22"
    user        = "ec2-user"
    keyPath     = "/root/.ssh/$VULS_KEY_NAME"

    [servers.ubuntu]
    host        = "$UBUNTU_IP"
    port        = "22"
    user        = "ubuntu"
    keyPath     = "/root/.ssh/$VULS_KEY_NAME"

    [servers.centos]
    host        = "$CENTOS_IP"
    port        = "22"
    user        = "centos"
    keyPath     = "/root/.ssh/$VULS_KEY_NAME"

    [servers.amazon]
    host        = "$REDHAT_IP"
    port        = "22"
    user        = "root"
    keyPath     = "/root/.ssh/$VULS_KEY_NAME"
EOS


  fi
  exit 0
 fi 


if [ $METHOD == "delete" ]; then
  aws cloudformation delete-stack --stack-name ${STACK_NAME_OPSWORKS}
  echo "deleting ${STACK_NAME_OPSWORKS}"
  aws cloudformation delete-stack --stack-name ${STACK_NAME_INSTTTANCES}
  echo "deleting ${STACK_NAME_INSTTTANCES}"
  aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME_OPSWORKS}
  aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME_INSTTTANCES}
  echo "vuls cloudformation is all deleted successfully"

  exit 0
fi
