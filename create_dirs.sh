#!/bin/bash
set -e
set -u 

PROJECT_NAME=""
COMPONENT_NAME=""
TEMPLATE_NAME=""
STAGE=""
SHARED_STAGE=""
PARAMS=""

PARAMS_STAGES_PART=""

function usage() {

cat << EOF
usage: $0 

        -h|--help
        -s|--stage STAGE_NAME
        -shared-stage STAGE_NAME
        -S|--template TEMPLATE_NAME
        -p|--project PROJECT_NAME
        -c|--component COMPONENT_NAME
        -P|--params PARAMS_NAME
        -r|--region REGION (not implemented yet)

  SHELL variables used by script (not implemented yet):
      PROJECT_NAME: $PROJECT_NAME
      COMPONENT_NAME: $COMPONENT_NAME

EOF

    # show_variables
    exit 1
}

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help) shift; usage;;
        -p|--project) shift; PROJECT_NAME=$1; shift;;
        -c|--component) shift; COMPONENT_NAME=$1; shift;;
        -s|--stage) shift; STAGE=$1; SHARED_STAGE=""; shift;;
        --shared-stage) shift; STAGE=""; SHARED_STAGE=$1; shift;;
        -S|--template) shift; TEMPLATE_NAME=$1; shift;;
        -P|--params) shift; PARAMS=$1; shift;;

        *) echo "Wrong option $1"; exit 1;
    esac
done;

if [ -z $PROJECT_NAME ]; then 
    echo "A parameter --project is missing. "
    usage
fi

if [ -z $COMPONENT_NAME ]; then 
    echo "A parameter --component is missing. "
    usage
fi

mkdir -p $PROJECT_NAME/$COMPONENT_NAME/{commands,parameters,templates}

if [ -z $TEMPLATE_NAME ]; then 
  exit 0
fi

PARAM_FILE_NAME_PART=""

if [ ! -z $STAGE ]; then

    if [ -z $PARAMS ]; then
      PARAM_FILE_NAME_PART="-${STAGE}"
    else 
      PARAM_FILE_NAME_PART="-${PARAMS}-${STAGE}"
    fi

    TEMPLATE_STAGES_PART="  Stage:
      Description: Stage name for resource
      Type: String
    "

 PARAMS_STAGES_PART=",
    {
        \"ParameterKey\": \"Stage\",
        \"ParameterValue\": \"$STAGE\"
    }"
elif [ ! -z $SHARED_STAGE ]; then

    if [ -z $PARAMS ]; then
      PARAM_FILE_NAME_PART="-${SHARED_STAGE}"
    else 
      PARAM_FILE_NAME_PART="-${PARAMS}-${SHARED_STAGE}"
    fi

 TEMPLATE_STAGES_PART="  SharedStage:
    Description: Stage name for shared resources
    Type: String
    AllowedValues:
      - shared-dev
      - shared-test
      - shared

 "

 PARAMS_STAGES_PART=",
    {
        \"ParameterKey\": \"SharedStage\",
        \"ParameterValue\": \"$SHARED_STAGE\"
    }"
else 
    if [ ! -z $PARAMS ]; then
      PARAM_FILE_NAME_PART="-${PARAMS}"
    fi
fi

echo "Creating files "
PARAM_FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/parameters/${TEMPLATE_NAME}${PARAM_FILE_NAME_PART}.json"
TEMPLATE_FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/templates/${TEMPLATE_NAME}.yaml"

if [ ! -f $TEMPLATE_FILE_NAME ]; then 
    echo "Creating tempalte file: >$TEMPLATE_FILE_NAME<"
    cat << OEF > $TEMPLATE_FILE_NAME
AWSTemplateFormatVersion: 2010-09-09
Description: Put here your description

Metadata: 

Parameters:
  Project:
    Description: Project name
    Type: String
    AllowedPattern: ^[a-z][a-zA-Z0-9-]{3,25}$
  Component:
    Description: Name of the component
    Type: String
    AllowedPattern: ^[a-z][a-zA-Z0-9-]{2,15}$
${TEMPLATE_STAGES_PART}

Resources:

Mappings: 

Conditions: 

Outputs:
OEF
fi


if [ -f $PARAM_FILE_NAME ]; then
      echo "The file $PARAM_FILE_NAME exist, not creating new one"
      exit 0
fi

echo "Creating param file: >$PARAM_FILE_NAME<"
cat << EOF > $PARAM_FILE_NAME
[
    {
        "ParameterKey": "Project",
        "ParameterValue": "$PROJECT_NAME"
    },
    {
        "ParameterKey": "Component",
        "ParameterValue": "$COMPONENT_NAME"
    }${PARAMS_STAGES_PART}
]
EOF

exit 0;
