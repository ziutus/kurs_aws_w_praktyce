#!/bin/bash
set -ue

API_URL=""
UPDATE_CONFIG=0
CONTENT_PATH=""
REGION=$(echo $AWS_REGION)

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help) shift; usage;;
        --conent-directory) shift; CONTENT_PATH=$1; shift;;
        -r|--region) shift; REGION=$1; shift;;
        --api_url) shift; API_URL=$1; shift;; 
        *) echo "Wrong option $1"; exit 1;
    esac
done;

[ -z $PROJECT ] && echo "Please setup environment variable PROJECT" && exit 1
[ -z $STAGE ] && echo "Please setup environment variable STAGE" && exit 1
[ -z $CONTENT_PATH ] && echo "Missing option --content-dircetory, please setup it" && exit 1
[ ! -d $CONTENT_PATH ] && echo "Wrong directory $CONTENT_PATH"


BUCKET=$(aws ssm get-parameter --name "/$PROJECT/$STAGE/application/website-bucket/name" --output text --query Parameter.Value --region "us-east-1")

set +e
CLOUDFRONT_URL=$(aws ssm get-parameter --name "/$PROJECT/$STAGE/cdn/cloudfrount/url" --output text --query Parameter.Value --region "us-east-1")
RC=$?
set -e
if [ $RC -eq 0 ]; then
    echo "CloudFront is configured, API_URL will be empty"
    UPDATE_CONFIG=1
    API_URL=""
else 
    set +e
    URL=$(aws ssm get-parameter --name "/$PROJECT/$STAGE/network/alb/url" --output text --query Parameter.Value --region $REGION)
    RC=$?
    set -e
    if [ $RC -eq 0 ]; then
        API_URL=$URL
        UPDATE_CONFIG=1
    else 
        if [ $API_URL == "" ]; then
            echo "Aplication Load Balancer is not configured, please manually provide API_URL by using option --api-url "
            exit 2
        else 
            echo "will use API_URL provided in command line"
        fi    
    fi
fi



[ -z $BUCKET ] && echo "Bucket for website doesn't exist, exiting..." && exit 1

if [ $UPDATE_CONFIG -eq 1 ]; then
    echo "Creating configuration file $CONTENT_PATH/configurations.js"
    cat << EOF > $CONTENT_PATH/configurations.js
var Configs = {
    "ApiURL": "$API_URL",
    "PhotosURL": "$API_URL"
};
EOF
fi


echo "Uploading to gui bucket: >$BUCKET<"
echo "Uploading from directory: >$CONTENT_PATH<"

aws s3 cp "$CONTENT_PATH" "s3://$BUCKET" --recursive

exit 0