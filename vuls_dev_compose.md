# vuls_dev_compose.sh

NOW IN PROGRESS.

## DESCRIPTION

vuls_dev_compose can automatically setup vuls development environment.

## DEPENDENCY

- [jq](https://github.com/stedolan/jq)
- awscli

## SETUP AWS

- Create AWS account
- Create IAM Policy

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStackResource",
                "cloudformation:DescribeStackResources",
                "cloudformation:GetTemplate",
                "cloudformation:List*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:PassRole",
                "iam:GetInstanceProfile",
                "iam:DeleteRolePolicy",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:DeleteRole",
                "iam:GetRole"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "opsworks:CreateStack",
                "opsworks:CreateInstance",
                "opsworks:CreateLayer",
                "opsworks:CreateApp",
                "opsworks:CreateDeployment",
                "opsworks:DeleteInstance",
                "opsworks:DeleteLayer",
                "opsworks:DeleteStack",
                "opsworks:DeleteApp",
                "opsworks:StartInstance",
                "opsworks:StopInstance",
                "opsworks:DescribeInstances",
                "opsworks:DescribeLayers",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:DescribeCommands",
                "opsworks:UpdateLayer"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

- Create IAM user having the policy
- Create Access key and store your local
## SETUP LOCAL

- install aws cli

```
$ brew insatll awscli
```

- clone this repo

```
$ git clone https://github.com/sadayuki-matsuno/vuls-cf.git
```

- Set env parameters as blow

```
export VULS_VPC_ID=vpc-1111111
export VULS_REGION=ap-northeast-1
export VULS_AZ=ap-northeast-1a
export VULS_KEY_NAME=vuls-dev
```

|Param|Explain|
|:--|:--|
|VULS_VPC_ID|VPC ID to launch Instaces.|
|VULS_REGION|Region to launch Instaces.|
|VULS_AZ|Availability Zone to launch Instaces.|
|VULS_KEY_NAME|Keyname to launch Instaces.|


## USAGE

- create compose

```
$ sh vuls_dev_compose.sh create
```

- delete compose

```
$ sh vuls_dev_compose.sh delete
```

# AUTHOR

Sadayuki Matsuno
