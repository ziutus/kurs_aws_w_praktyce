#! /bin/bash
set -u
set -e 

# action='start_paid'
action='delete_paid'

STEP=12

# [ $STEP -eq 10 ] && application/commands/upload-cw-config.sh && STEP=11
# [ $STEP -eq 11 ] && application/commands/upload-srv-config.sh && STEP=12
# [ $STEP -eq 11 ] && application/commands/upload-pictures.sh && STEP=13

if [ $action == "delete_paid" ]; then
    set +x
    aws cloudformation delete-stack --stack memes-generator2-dev-load-balancing
    aws cloudformation delete-stack --stack memes-generator2-dev-application-auto-scaling
    aws cloudformation delete-stack --stack memes-generator2-dev-application-application-instance
    aws cloudformation delete-stack --stack memes-generator2-dev-operations-jumphost-db
    aws cloudformation delete-stack --stack memes-generator2-dev-network-nat-gateway-azA
    aws cloudformation delete-stack --stack memes-generator2-dev-network-nat-gateway-azB
    set -x
fi

if [ $action == "start_paid" ]; then
    ./deploy.sh --project memes-generator2 --stage dev --component network --stack nat-gateway-azA --exec
    ./deploy.sh --project memes-generator2 --stage dev --component network --stack nat-gateway-azB --exec
    # ./deploy.sh --project memes-generator2 --stage dev --component application --stack application-instance --exec
    ./deploy.sh --project memes-generator2 --stage dev --component operations --stack jumphost-db --exec
    ./deploy.sh --project memes-generator2 --stage dev --component network --stack application-auto-scaling --exec
    ./deploy.sh --project memes-generator2 --stage dev --component network --stack load-balancing --exec
fi

exit 0