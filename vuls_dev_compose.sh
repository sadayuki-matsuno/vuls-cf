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

[ $# -ne 1 ] && { echo "One argument is permitted"; help_arg; }
if [ $1 == "create" ]; then
  METHOD=create
elif [ $1 == "delete" ]; then
  METHOD=delete
else
  echo "Wrong arguments supplied"; help_arg
fi

######################################################
# Parameter Check
## You shoud set blow parameters at env
######################################################




######################################################
# Parameter Check
## You shoud set blow parameters at env
######################################################

function help_param() {
  cat <<- EOS

set blow parameters at your env
  VULS_VPC_ID:     vpc id (ex. vpc-11111111)
  VULS_REGION:     region (ex. ap-northeast-1)
  VULS_AZ:         availability zone (ex. ap-northeast-1a)
  VULS_KEY_NAME:   ssh key name (ex. vuls-dev)
  VULS_PURPOSE:    default or unsecure (ex. default)

EOS
  exit 1
}

[ -z "$VULS_VPC_ID" ] && { echo "Need to set VULS_VPC_ID"; help_param; }
[ -z "$VULS_REGION" ] && { echo "Need to set VULS_REGION"; help_param; }
[ -z "$VULS_AZ" ] && { echo "Need to set VULS_AZ"; help_param; }
[ -z "$VULS_KEY_NAME" ] && { echo "Need to set VULS_KEY_NAME"; help_param; }
[ -z "$VULS_PURPOSE" ] && { echo "Need to set VULS_PURPOSE"; help_param; }
CURRENT_DIR=$(cd $(dirname $0);pwd)

######################################################
# Create Instaces
######################################################

if [ $METHOD == "create" ]; then

  aws cloudformation create-stack \
     --stack-name vuls-dev \
     --template-body file:///#${CURRENT_DIR}/vuls-dev.template \
     --region ${VULS_REGION} \
     --parameters \
  	ParameterKey=VPC,ParameterValue=${VULS_VPC_ID} \
  	ParameterKey=AZ,ParameterValue=${VULS_AZ} \
  	ParameterKey=Keyname,ParameterValue=${VULS_KEY_NAME} \
  	ParameterKey=VulsScanServerIP,ParameterValue="" \
  	ParameterKey=Purpose,ParameterValue=${VULS_PURPOSE}
  
  exit 1
 fi 
