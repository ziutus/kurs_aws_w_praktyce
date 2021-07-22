#! /bin/bash
set -u
# set -x

# curl -X GET http://localhost:8080/actuator/health

REGION=$(echo $AWS_REGION)


ALB_URL=$(aws ssm get-parameter --name '/memes-generator2/dev/network/alb/url' --query 'Parameter.Value' --region $REGION 2>&1 )
RC=$?

if [ $RC -ne 0 ]; then
    echo "The Application load balancer is not configured"
    exit 1
fi

ALB_URL=$(echo $ALB_URL | sed s/\"//g)
echo "ALB_URL: $ALB_URL"

STATUS=$(curl -s -X GET http://${ALB_URL}/actuator/health | jq -r '.status')

if [ "$STATUS" == 'UP' ]; then
    echo "ALB status: [OK]"
else 
    echo "Something went wrong, status is: >$STATUS<"
    exit 1    
fi

exit 0