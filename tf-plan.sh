#!/usr/bin/env bash
echo "REPOSITORY: terraform-aws-init"
echo "SCRIPT: tf-plan.sh <s3_prefix> <region> <public_key>"
echo "EXECUTING: terraform plan"

echo "Checking for aws cli..."
if ! [ -x "$(command -v aws)" ]; then
    echo 'Error: aws cli is not installed.' >&2
    exit 1
fi

s3_prefix=$1
if [ -z "$s3_prefix" ]; then
    s3_prefix="brick-new"
    echo "No s3 prefix was passed in, using \"${s3_prefix}\" as the default"
fi

# Set target aws region
target_aws_region=$2
if [ -z "$target_aws_region" ]; then
    target_aws_region="us-east-1"
    echo "No region was passed in, using \"${target_aws_region}\" as the default"
fi

# Set public key
public_key=$3
if [ -z "$public_key" ]; then
    # Public ssh key location on your local HD
    public_key=~/.pems/PatientAlertKeys/pa_ssh_key.pub
    echo "No public key was passed in, using \"${public_key}\" as the default"
fi
# Check the key exists
if [ ! -f ${public_key} ]; then
    echo "Error: public key \"${public_key}\" does not exist!" >&2
    exit 1
fi

# Get the contents of your ssh key
ssh_key=$(cat ${public_key})

#Download plugins
terraform init

# Needed for Terraform AWS Provider {}
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

# Uncomment for verbose terraform output
#export TF_LOG=info

echo "terraform plan -var \"s3prefix=${s3_prefix}\" -var \"ssh_key=${ssh_key}\" -var \"region=${target_aws_region}\""
if terraform plan -var "s3prefix=${s3_prefix}" -var "ssh_key=${ssh_key}" -var "region=${target_aws_region}" ; then
    echo "Terraform plan succeeded."
else
    echo 'Error: terraform plan failed.' >&2
    exit 1
fi

echo "Plan Completed"
