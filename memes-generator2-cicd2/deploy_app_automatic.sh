#! /bin/bash
export PROJECT="memes-generator2-cicd2"
export SHARED_STAGE="shared-dev"
export STAGE=""

STEP=9

[[ $STEP -le 1 ]] && ./deploy.sh --component cicd --template-name account-parameters --exec
[[ $STEP -le 2 ]] && ./deploy.sh --component cicd --template-name git-repository --params cicd --exec
[[ $STEP -le 3 ]] && ./deploy.sh --component cicd --template-name git-repository --params infra --exec
[[ $STEP -le 4 ]] && ./deploy.sh --component cicd --template-name kms --exec
[[ $STEP -le 5 ]] && ./deploy.sh --component cicd --template-name cicd-roles --exec
# step 6 connected with step 6
[[ $STEP -le 7 ]] && ./deploy.sh --component cicd --template-name ssm-command-create-db-user --exec
[[ $STEP -le 8 ]] && ./deploy.sh --component cicd --template-name cicd-resources --exec
[[ $STEP -le 9 ]] && ./deploy.sh --component cicd --template-name pipeline-resources-create --exec

#  creating code build projects to run shell scripts
# [[ $STEP -le 10 ]] && ./deploy.sh --component cicd --template-name build-project --params create-db-user --exec
# [[ $STEP -le 11 ]] && ./deploy.sh --component cicd --template-name build-project --params test-and-create-config --exec
# [[ $STEP -le 11 ]] && ./deploy.sh --component cicd --template-name build-project --params upload-files --exec

# [[ $STEP -le 12 ]] && ./deploy.sh --component cicd --template-name build-project --params upload-files --exec



exit 0