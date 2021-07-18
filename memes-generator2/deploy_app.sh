#! /bin/bash
set -u
set -e 

PROJECT="memes-generator2"
STAGE="dev"

action='create_paid'
# action='delete_paid'

STEP=12

if [ ! -d $PROJECT ]; then
    1>&2 echo STDERR "Can't find directory ./$PROJECT"
    1>&2 echo "This script should be called from base diectory"
    1>&2 echo "exiting..."
    exit 2
fi

# [ $STEP -eq 10 ] && application/commands/upload-cw-config.sh && STEP=11
# [ $STEP -eq 11 ] && application/commands/upload-srv-config.sh && STEP=12
# [ $STEP -eq 11 ] && application/commands/upload-pictures.sh && STEP=13

if [ $action == "delete_paid" ]; then
    set +x
    echo "Stopping db instance - it can take 2-3 minutes"
    aws rds stop-db-instance --db-instance-identifier ${PROJECT}-${STAGE}-data-db
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-load-balancing
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-application-auto-scaling
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-application-application-instance
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-operations-jumphost-db
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-nat-gateway-azA
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-nat-gateway-azB
    set -x
fi

if [ $action == "create_paid" ]; then
    echo "Starting db instance - it can take 2-3 minutes"
    # TODO add check if db is already started
    # aws rds start-db-instance --db-instance-identifier ${PROJECT}-${STAGE}-data-db
    ./deploy.sh --project ${PROJECT} --stage $STAGE --component network --stack nat-gateway-azA --exec
    ./deploy.sh --project ${PROJECT} --stage $STAGE --component network --stack nat-gateway-azB --exec
    # ./deploy.sh --project ${PROJECT} --stage $STAGE --component application --stack application-instance --exec
    ./deploy.sh --project ${PROJECT} --stage $STAGE --component operations --stack jumphost-db --exec
    ./deploy.sh --project ${PROJECT} --stage $STAGE --component network --stack application-auto-scaling --exec
    ./deploy.sh --project ${PROJECT} --stage $STAGE --component network --stack load-balancing --exec

fi


### week 9
# [ $STEP -eq 11 ] && ./deploy.sh --project ${PROJECT} --stage dev --component application --stack bucket --params website --region "us-east-1" --exec


exit 0