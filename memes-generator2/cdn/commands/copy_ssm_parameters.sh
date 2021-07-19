#! /bin/bash

SOURCE_REGION=$(echo $AWS_REGION)

[ -z $SOURCE_REGION ] && echo "Please setup environment variable AWS_REGION" && exit 1
[ -z $PROJECT ] && echo "Please setup environment variable PROJECT" && exit 1
[ -z $STAGE ] && echo "Please setup environment variable STAGE" && exit 1

TARGET_REGION="us-east-1"

ALB_PARAM_NAME="/$PROJECT/$STAGE/network/alb/url"
ALB_PARAM=$(aws ssm get-parameter --name $ALB_PARAM_NAME --query 'Parameter.Value' --region $SOURCE_REGION)

ALB_PARAM=$(echo $ALB_PARAM | sed 's/\"//g')

aws ssm put-parameter \
    --name $ALB_PARAM_NAME \
    --value $ALB_PARAM \
    --type String \
    --description "SSM Parameter that stores ALB url" \
    --overwrite \
    --region $TARGET_REGION
