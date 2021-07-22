#! /bin/bash
set -u
set -e 

# PROJECT="memes-generator2"
# STAGE="dev"
action=""
STEP=12

while [ $# -gt 0 ]; do
    case $1 in
        # -h|--help) shift; usage;;
        -s|--stage) shift; STAGE=$1; shift;;
        -p|--project) shift; PROJECT_NAME=$1; shift;;
        --delete) shift; action='delete_paid';;
        --create) shift; action='create_paid';;
        --step) shift; STEP=$1;;  
        *) echo "Wrong option $1"; exit 1;
    esac
done;

if [ -z $PROJECT ]; then
    1>&2 echo "please setup env. variable PROJECT or use option --project PROJECT_NAME "
    1>&2 echo "exiting..."
    exit 2
fi

if [ -z $STAGE ]; then
    1>&2 echo "please setup env. variable STAGE or use option --stage STAGE "
    1>&2 echo "exiting..."
    exit 2
fi

if [ ! -d $PROJECT ]; then
    1>&2 echo "Can't find directory ./$PROJECT"
    1>&2 echo "This script should be called from base diectory"
    1>&2 echo "exiting..."
    exit 2
fi

if [ -z $action ]; then 
    1>&2 echo "No action! You should use one of --delete or --create"
    1>&2 echo "exiting..."
    exit 2
fi

# [ $STEP -eq 10 ] && application/commands/upload-cw-config.sh && STEP=11
# [ $STEP -eq 11 ] && application/commands/upload-srv-config.sh && STEP=12
# [ $STEP -eq 11 ] && application/commands/upload-pictures.sh && STEP=13

if [ "$action" == "delete_paid" ]; then
    set +x
    echo "Stopping db instance - it can take 2-3 minutes"
    aws rds stop-db-instance --db-instance-identifier ${PROJECT}-${STAGE}-data-db
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-waf-aws-waf-security-automations --region "us-east-1"

    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-cdn-cloudfront --region "us-east-1"
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-load-balancing
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-application-auto-scaling
    # aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-application-application-instance
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-operations-jumphost-db
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-nat-gateway-azA
    aws cloudformation delete-stack --stack ${PROJECT}-${STAGE}-network-nat-gateway-azB
    set -x
fi

if [ "$action" == "create_paid" ]; then
    echo "Starting db instance - it can take 2-3 minutes"
    # TODO add check if db is already started
    aws rds start-db-instance --db-instance-identifier ${PROJECT}-${STAGE}-data-db
    ./deploy.sh --component network --stack nat-gateway-azA --exec
    ./deploy.sh --component network --stack nat-gateway-azB --exec
    # ./deploy.sh --component application --stack application-instance --exec
    # ./deploy.sh --component operations --stack jumphost-db --exec
    ./deploy.sh --component network --stack application-auto-scaling --exec
    ./deploy.sh --component network --stack load-balancing --exec

    $PROJECT/cdn/commands/copy_ssm_parameters.sh

    ./deploy.sh --component waf --stack aws-waf-security-automations -exec
    ./deploy.sh --component cdn --stack cloudfront --exec

fi


### week 9
# [ $STEP -eq 11 ] && ./deploy.sh --project ${PROJECT} --stage ${STAGE} --component application --stack bucket --params website --exec


exit 0