#!/bin/bash
set -e
set -u 
# set -x

VERSION="1.4"
VERSION_CODE_NAME="region version"

REGION_DEFAULT=$(echo $AWS_REGION)
REGION_FORCE=""
REGION_PARAMS=""

STAGE=$(echo $STAGE)
SHARED_STAGE=$(echo $SHARED_STAGE)
PROJECT_NAME=$(echo $PROJECT)

function show_variables() {
cat << EOF
base dirname: >$DIRNAME<
project name: >$PROJECT_NAME<
component name: >$COMPONENT_NAME<
region: >$REGION<
stage: >$STAGE<
template: >$TEMPLATE<
TEMPLATE_FILE: >$TEMPLATE_FILE<
PARAM_FILE: >$PARAM_FILE<
STACK_NAME: >$STACK_NAME<

EOF
}

function usage() {

cat << EOF
usage: $0 

        -h|--help
        -s|--stage STAGE_NAME
        -shared-stage STAGE_NAME
        -S|--stack STACK_NAME
        -p|--project PROJECT_NAME
        -c|--component COMPONENT_NAME
        -P|--params PARAMS_NAME
        -r|--region REGION
        --list-params
        --list-stacks
        --list-components
        --list-projects
        --exec
        --preview

Link to AWS documentation: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/deploy/index.html
EOF

    # show_variables
    exit 1
}

function listProjects() {
    echo "Possible projects in: >$DIR_NAME<"
    find $DIR_NAME -mindepth 1 -maxdepth 1 -type d | egrep -v  ".git" 
    exit 1
}

function listComponents() {
    echo "Possible components in >$PROJECT_PATH<:"
    find $PROJECT_PATH -mindepth 1 -maxdepth 1 -type d | egrep -v  ".git" | sed "s/\/$PROJECT_NAME\///" | sed "s/\.//g"
    exit 1
}

function listStacks() {
    echo "Possible stacks in >$COMPONENT_PATH/templates<:"
    find $COMPONENT_PATH/templates -mindepth 1 -maxdepth 1 -type f
    exit 1

}

function listParamFiles() {
    echo "Possible Parameters files in $COMPONENT_PATH/parameters/"
    find $COMPONENT_PATH/parameters/ -ls
    echo "Please remember that you don't need to put STACK part in --params parameters"
    exit 1
}



STACK_NAME=""
COMPONENT_NAME=""
DIR_NAME=""
PARAMS=""
LIST_PROJECTS=0
LIST_PARAMS=0
LIST_COMPONENTS=0
LIST_STACKS=0
EXEC=0

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help) shift; usage;;
        -s|--stage) shift; STAGE=$1; SHARED_STAGE=""; shift;;
        --shared-stage) shift; SHARED_STAGE=$1; STAGE=""; shift;;
        -S|--stack) shift; STACK_NAME=$1; shift;;
        -p|--project) shift; PROJECT_NAME=$1; shift;;
        -c|--component) shift; COMPONENT_NAME=$1; shift;;
        -P|--params) shift; PARAMS=$1; shift;;
        -r|--region) shift; REGION_FORCE=$1; shift;;
        --list-params) shift; LIST_PARAMS=1;;
        --list-components) shift; LIST_COMPONENTS=1;;
        --list-stacks) shift; LIST_STACKS=1;;
        --list-projects) shift; LIST_PROJECTS=1;;
        --exec) shift; EXEC=1;;
        --preview) shift; EXEC=0;;
        *) echo "Wrong option $1"; exit 1;
    esac
done;

#TODO: Check if region has correct name if got from command line
#TODO: Add check if s3 bucket for templates exist
#TODO: Add task to create s3 bucket if needed

if  [ -z $PROJECT_NAME ]; then
    echo "guessing project name from path"
    DIR_NAME=$(dirname $0)
    if [[ "$DIR_NAME" == "." ]]; then
        DIRNAME=$(pwd)
    fi

    [ $LIST_PROJECTS -eq 1 ] && listProjects

    if [ -z $COMPONENT_NAME ]; then 
        COMPONENT_PATH=$(dirname $DIR_NAME)
        COMPONENT_NAME=$(basename $COMPONENT_PATH)
        PROJECT_PATH=$(dirname $COMPONENT_PATH)
        PROJECT_NAME=$(basename $PROJECT_PATH)
    fi

    # echo " -- dirname: $DIR_NAME"
    echo " -- project name: $PROJECT_NAME"
    echo " -- compomnent name: $COMPONENT_NAME"
else 
    echo " setup project path and component path from command line options"
    PROJECT_PATH="./$PROJECT_NAME"
    echo -n " -- project path: $PROJECT_PATH"
    if [ ! -d $PROJECT_PATH ]; then
        echo " [Error!]"
        echo "The directory $PROJECT_PATH doesn't exist"
        exit 1
    fi
    echo " [OK]"

    if [ -z $COMPONENT_NAME ] || [ $LIST_COMPONENTS -eq 1 ]; then 
        listComponents
    fi     


    COMPONENT_PATH="./$PROJECT_NAME/$COMPONENT_NAME"
    echo -n " -- component path: $COMPONENT_PATH"
    if [ ! -d $COMPONENT_PATH ]; then
        echo " [Error!]"
        echo "The directory $COMPONENT_PATH doesn't exist"
        exit 1
    fi
    echo " [OK]"
fi

TEMPLATE=""
TEMPLATE_FILE=""
PARAM_FILE=""

if [ -z $STAGE ] && [ -z $SHARED_STAGE ]; then 
    echo "A parameter --stage or --shared-stage is missing. "
    usage
fi

[ $LIST_STACKS -eq 1 ] && listStacks

if [ -z $STACK_NAME ]; then 
    echo "A parameter --stack is missing. "
    listStacks
fi

[ $LIST_PARAMS -eq 1 ] && listParamFiles

echo -n "Checking if template file exist in $COMPONENT_PATH/templates/"
if [ -f "$COMPONENT_PATH/templates/${STACK_NAME}-${STAGE}.yaml" ]; then
    TEMPLATE_FILE="$COMPONENT_PATH/${STACK_NAME}-${STAGE}.yaml"
    echo " [OK]"
elif [ -f "$COMPONENT_PATH/templates/${STACK_NAME}-${SHARED_STAGE}.yaml" ]; then
    TEMPLATE_FILE="$COMPONENT_PATH/${STACK_NAME}-${SHARED_STAGE}.yaml"
    echo " [OK]"    
else
    TEMPLATE_FILE="$COMPONENT_PATH/templates/${STACK_NAME}.yaml"
    if [ ! -f $TEMPLATE_FILE ]; then 
        echo "Can't file template file >$TEMPLATE_FILE<, is this correct stack?"
        exit 2
    fi
    echo ' [OK]'
fi

echo "params >$PARAMS< "
if [ -z $PARAMS ]; then
    echo -n "Checking if default parameter file exist in $COMPONENT_PATH/parameters/"
    if [ -f "$COMPONENT_PATH/parameters/${STACK_NAME}-${STAGE}.json" ]; then
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${STAGE}.json"
    elif [ -f "$COMPONENT_PATH/parameters/${STACK_NAME}-${SHARED_STAGE}.json" ]; then
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${SHARED_STAGE}.json"
    else
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}.json"
        if [ ! -f $PARAM_FILE ]; then 
            echo "Can't file parameters file >$PARAM_FILE<, is this correct stack?"
            exit 2
        fi
    fi
else 
    echo -n "Checking if special parameter file exist in $COMPONENT_PATH/parameters/"
    if [ -f "$COMPONENT_PATH/parameters/${STACK_NAME}-${PARAMS}-${STAGE}.json" ]; then
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${PARAMS}-${STAGE}.json"
    elif [ -f "$COMPONENT_PATH/parameters/${STACK_NAME}-${PARAMS}-${SHARED_STAGE}.json" ]; then
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${PARAMS}-${SHARED_STAGE}.json"
    else
        PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${PARAMS}.json"
        if [ ! -f $PARAM_FILE ]; then 
            echo "Can't file parameters file >$PARAM_FILE<, is this correct stack?"
            exit 2
        fi
    fi

fi
echo " [OK]"

echo "Checking if parameters in PARAM files are the same as in command line to aviod problems after simple copy of files:"
echo -n "  -- Checking PROJECT NAME"
PARAMS_PROJECT_NAME=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "Project" ) | .ParameterValue ')
if [ "$PARAMS_PROJECT_NAME" == "$PROJECT_NAME" ]; then
    echo " [OK]";
else 
    echo " [ERROR!]";
    echo "Project name >$PARAMS_PROJECT_NAME< in PARAM file >$PARAM_FILE< is different that >$PROJECT_NAME< from directory structure, please check Param fIle "
    exit 4
fi

echo -n "  -- Checking STAGE or SHARED_STAGE"
PARAMS_STAGE=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "Stage" ) | .ParameterValue ')
if [ "$PARAMS_STAGE" == "$STAGE" ]; then
    echo " [OK]";
else 
    PARAMS_SHARED_STAGE=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "SharedStage" ) | .ParameterValue ')
    if [ "$PARAMS_SHARED_STAGE" == "$SHARED_STAGE" ] && [ ! -z $SHARED_STAGE ]; then
        echo " [OK]";
    else 
        echo " [ERROR!]";
        echo "Stage name (or shared stage name) in PARAM file >$PARAM_FILE< is different that >$STAGE< from command line, please check Param file "
        exit 4
    fi
fi

echo -n "  -- Checking COMPONENT"
PARAMS_COMPONENT=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "Component" ) | .ParameterValue ')
if [ "$PARAMS_COMPONENT" == "$COMPONENT_NAME" ]; then
    echo " [OK]";
else 
    echo " [ERROR!]";
    echo "Component name >$PARAMS_COMPONENT< in PARAM file >$PARAM_FILE< is different that >$COMPONENT_NAME< from directory structure, please check the it "
    exit 4
fi

echo "All prechecks status [OK]";
echo ""


echo "Checking region setup"
REGION=$REGION_DEFAULT
PARAMS_REGION=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "Region" ) | .ParameterValue ')
echo "region default: >$REGION_DEFAULT<"
echo "region from param file: >$PARAMS_REGION<"
echo "region from command line (overwrite all): >$REGION_FORCE<"
[ ! -z $PARAMS_REGION ] && REGION=$PARAMS_REGION
[ ! -z $REGION_FORCE ] && REGION=$REGION_FORCE
echo "region final: >$REGION<"


set +eu
S3_BUCKET=$(aws ssm get-parameter --name /${PROJECT_NAME}/${STAGE}/operations/cloudformation-bucket/name --output text --query Parameter.Value --region $REGION 2>&1)
RC=$?
set -eu
S3_BUCKET_PART=""
if [[ $RC -eq 0 ]]; then 
    echo "Found S3 bucket for Cloudformation templates: >$S3_BUCKET<"
    S3_BUCKET_PART="--s3-bucket $S3_BUCKET "
fi

if [ -z $PARAMS ]; then
    if [ ! -z $STAGE ]; then 
        STACK_NAME="${PROJECT_NAME}-${STAGE}-${COMPONENT_NAME}-${STACK_NAME}"
    elif [ ! -z $SHARED_STAGE ]; then
        STACK_NAME="${PROJECT_NAME}-${SHARED_STAGE}-${COMPONENT_NAME}-${STACK_NAME}"
    fi    
else 
    if [ ! -z $STAGE ]; then 
        STACK_NAME="${PROJECT_NAME}-${STAGE}-${COMPONENT_NAME}-${PARAMS}-${STACK_NAME}"
    elif [ ! -z $SHARED_STAGE ]; then
        STACK_NAME="${PROJECT_NAME}-${SHARED_STAGE}-${COMPONENT_NAME}-${PARAMS}-${STACK_NAME}"
    fi
fi

if [ ! -z $STAGE ]; then 
    STAGE_TAG="Stage=$STAGE"
else
    STAGE_TAG="SharedStage=$SHARED_STAGE"
fi

COMMAND="aws cloudformation deploy  \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides file://$PARAM_FILE \
    --region $REGION $S3_BUCKET_PART \
    --tags Project=$PROJECT_NAME $STAGE_TAG Component=$COMPONENT_NAME"

echo "" 
echo $COMMAND

if [ $EXEC -eq 0 ]; then
    echo ""
    echo "it is preview, no action taken. Add --exec to execute command"
    exit 0
fi


set +e
$COMMAND
RC=$?

if [ $RC -eq 0 ]; then
    outputs="aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --output table \
        --query Stacks[].Outputs[] \
        --region $REGION"

    echo "$outputs"
    $outputs
else
    echo ""
    echo "if you want to remove problematic stack call below command"
    echo "aws cloudformation delete-stack --stack $STACK_NAME"    
fi



exit 0