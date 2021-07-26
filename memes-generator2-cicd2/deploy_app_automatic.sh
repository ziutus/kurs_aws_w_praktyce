#! /bin/bash
export PROJECT="memes-generator2-cicd2"
export SHARED_STAGE="shared-dev"
export STAGE=""

STEP=7

[[ $STEP -le 1 ]] && ./deploy.sh --component cicd --stack account-parameters --exec
[[ $STEP -le 2 ]] && ./deploy.sh --component cicd --stack git-repository --params cicd --exec
[[ $STEP -le 3 ]] && ./deploy.sh --component cicd --stack git-repository --params infra --exec
[[ $STEP -le 4 ]] && ./deploy.sh --component cicd --stack kms --exec
[[ $STEP -le 5 ]] && ./deploy.sh --component cicd --stack cicd-roles --exec
# step 6 connected with step 6
[[ $STEP -le 7 ]] && ./deploy.sh --component cicd --stack ssm-command-create-db-user --exec


exit 0