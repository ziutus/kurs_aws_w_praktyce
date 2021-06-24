#!/bin/bash
set -e
set -u 

VERSION="1.2"
VERSION_CODE_NAME="simple_site_import_export"

DIRNAME=$(dirname $0)
if [[ "$DIRNAME" == "." ]]; then
    DIRNAME=$(pwd)
fi

REGION=$(echo $AWS_REGION)

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

Link to AWS documentation: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/deploy/index.html
EOF

    # show_variables
    exit 1
}


STACK_NAME=""
STAGE=""
PROJECT_NAME=""
PROJECT_NAME=""

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help) shift; usage;;
        -s|--stage) shift; STAGE=$1; shift;;
        -S|--stack) shift; STACK_NAME=$1; shift;;
        -p|--project) shift; PROJECT_NAME=$1; shift;;
        -c|--component) shift; COMPONENT_NAME=$1; shift;;

        *) echo "Wrong option $1"; exit 1;
    esac
done;

if  [ -z $PROJECT_NAME ] && [ -z $COMPONENT_NAME ]; then
    echo "guessing project name and component from path"
    COMPONENT_PATH=$(dirname $DIRNAME)
    COMPONENT_NAME=$(basename $COMPONENT_PATH)
    PROJECT_PATH=$(dirname $COMPONENT_PATH)
    PROJECT_NAME=$(basename $PROJECT_PATH)
    echo " -- project name: $PROJECT_NAME"
    echo " -- compomnent name: $COMPONENT_PATH"
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

if [ -z $STAGE ]; then 
    echo "A parameter --stage is missing. "
    usage
fi

if [ -z $STACK_NAME ]; then 
    echo "A parameter --stack is missing. "
    usage
fi

echo -n "Checking if template file exist in $COMPONENT_PATH/templates/"
if [ -f "$COMPONENT_PATH/templates/${STACK_NAME}-${STAGE}.yaml" ]; then
    TEMPLATE_FILE="$COMPONENT_PATH/${STACK_NAME}-${STAGE}.yaml"
    echo " [OK]"
else
    TEMPLATE_FILE="$COMPONENT_PATH/templates/${STACK_NAME}.yaml"
    if [ ! -f $TEMPLATE_FILE ]; then 
        echo "Can't file template file >$TEMPLATE_FILE<, is this correct stack?"
        exit 2
    fi
    echo ' [OK]'
fi

echo -n "Checking if parameter file exist in $COMPONENT_PATH/parameters/"
if [ -f "$COMPONENT_PATH/parameters/${STACK_NAME}-${STAGE}.json" ]; then
    PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}-${STAGE}.json"
    echo "[OK]"
else
    PARAM_FILE="$COMPONENT_PATH/parameters/${STACK_NAME}.json"
    if [ ! -f $PARAM_FILE ]; then 
        echo "Can't file parameters file >$PARAM_FILE<, is this correct stack?"
        exit 2
    fi
    echo " [OK]"
fi

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

echo -n "  -- Checking STAGE"
PARAMS_STAGE=$(cat $PARAM_FILE | jq -r '.[] | select( .ParameterKey == "Stage" ) | .ParameterValue ')
if [ "$PARAMS_STAGE" == "$STAGE" ]; then
    echo " [OK]";
else 
    echo " [ERROR!]";
    echo "Stage name in PARAM file >$PARAM_FILE< is different that >$STAGE< from command line, please check Param file "
    exit 4
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

COMMAND="aws cloudformation deploy  \
    --template-file $TEMPLATE_FILE \
    --stack-name ${PROJECT_NAME}-${STAGE}-${COMPONENT_NAME}-${STACK_NAME} \
    --no-fail-on-empty-changeset \
    --parameter-overrides file://$PARAM_FILE \
    --region $REGION \
    --tags Project=$PROJECT_NAME Stage=$STAGE Component=$COMPONENT_NAME"
    # --capabilities CAPABILITY_NAMED_IAM \

echo $COMMAND

$COMMAND
RC=$?

if [ $RC -eq 0 ]; then
    outputs="aws cloudformation describe-stacks \
        --stack-name ${PROJECT_NAME}-${STAGE}-${COMPONENT_NAME}-${STACK_NAME} \
        --output table \
        --query Stacks[].Outputs[] \
        --region $REGION"

    echo "$outputs"
    $outputs
fi

exit 0