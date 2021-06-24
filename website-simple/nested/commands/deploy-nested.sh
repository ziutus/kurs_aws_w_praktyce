#!/bin/bash
set -e
set -u 

PROJECT="website-simple"
STAGE="dev"
REGION="eu-west-1"
COMPONENT="nested"

######### Artifact bucket #########
STACK="artifact-bucket"

TEMPLATE_FILE="$PROJECT/$COMPONENT/templates/${STACK}.yaml"
PARAM_FILE="$PROJECT/$COMPONENT/parameters/${STACK}-$STAGE.json"

deploy="aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $PROJECT-$STAGE-$COMPONENT-$STACK \
    --no-fail-on-empty-changeset \
    --parameter-overrides file://$PARAM_FILE \
    --region $REGION \
    --tags Project=$PROJECT Stage=$STAGE Component=$COMPONENT"

echo $deploy

$deploy

######### Nested #########

STACK="nested"
TEMPLATE="root"
PARAMETERS="root"

######### common part #########

# Get artifact bucket name
S3_FOR_TEMPLATES=$(aws ssm get-parameters --names "/$PROJECT/$STAGE/$COMPONENT/artifact-bucket/bucket-name" --query "Parameters[*].{Name:Name,Value:Value}" | jq -r ".[].Value")
echo "$S3_FOR_TEMPLATES"

# Package the nested template

TEMPLATE_FILE="$PROJECT/$COMPONENT/templates/$TEMPLATE.yaml"
TEMPLATE_PACKAGED="$PROJECT/$COMPONENT/templates/$TEMPLATE-packaged.yaml"

package="aws cloudformation package \
     --template-file $TEMPLATE_FILE \
     --output-template $TEMPLATE_PACKAGED \
     --s3-bucket $S3_FOR_TEMPLATES"

echo $package

$package

# Deploy

PARAM_FILE="$PROJECT/$COMPONENT/parameters/root.json"

deploy="aws cloudformation deploy \
    --template-file $TEMPLATE_PACKAGED \
    --stack-name $PROJECT-$STAGE-$COMPONENT-$STACK \
    --no-fail-on-empty-changeset \
    --parameter-overrides file://$PARAM_FILE \
    --region $REGION \
    --tags Project=$PROJECT Stage=$STAGE Component=$COMPONENT"

echo $deploy

$deploy