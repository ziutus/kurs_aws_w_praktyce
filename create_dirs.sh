#!/bin/bash
set -e
set -u 

PROJECT_NAME=""
COMPONENT_NAME=""
STACK_NAME=""
STAGE=""
PARAMS=""

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help) shift; usage;;
        -p|--project) shift; PROJECT_NAME=$1; shift;;
        -c|--component) shift; COMPONENT_NAME=$1; shift;;
        -s|--stage) shift; STAGE=$1; shift;;
        -S|--stack) shift; STACK_NAME=$1; shift;;
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

if [ ! -z $STACK_NAME ]; then 

  TEMPLATE_FILE="$PROJECT_NAME/$COMPONENT_NAME/templates/${STACK_NAME}.yaml"
  if [ ! -f $TEMPLATE_FILE ]; then 
    cat << OEF > $TEMPLATE_FILE
AWSTemplateFormatVersion: 2010-09-09
Description: Put here your description

Metadata: 

Parameters:
  Project:
    Description: Project name
    Type: String
    AllowedPattern: ^[a-z][a-zA-Z0-9-]{3,20}$
  Component:
    Description: Name of the component
    Type: String
    AllowedPattern: ^[a-z][a-zA-Z0-9-]{2,15}$
  Stage:
    Description: Stage name
    Type: String
    AllowedPattern: ^[a-z][a-zA-Z0-9-]{2,15}$

Resources:

Mappings: 

Conditions: 

Outputs:
OEF
  fi

  if [ -z $STAGE ]; then
    if [ -z $PARAMS ]; then
      FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/parameters/$STACK_NAME.json"
    else 
      FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/parameters/$STACK_NAME-${PARAMS}.json"
    fi
    
    if [ -f $FILE_NAME ]; then
      echo "The file $FILE_NAME exist, not creating new one"
    else
      cat << EOF > $FILE_NAME
[
    {
        "ParameterKey": "Project",
        "ParameterValue": "$PROJECT_NAME"
    },
    {
        "ParameterKey": "Component",
        "ParameterValue": "$COMPONENT_NAME"
    }
]
EOF
    fi
  else 
    if [ -z $PARAMS ]; then
      FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/parameters/$STACK_NAME-${STAGE}.json"
    else 
      FILE_NAME="$PROJECT_NAME/$COMPONENT_NAME/parameters/$STACK_NAME-${PARAMS}-${STAGE}.json"
    fi
    

    if [ -f $FILE_NAME ]; then
      echo "The file $FILE_NAME exist, not creating new one"
    else 
      cat << EOF > $FILE_NAME
[
    {
        "ParameterKey": "Project",
        "ParameterValue": "$PROJECT_NAME"
    },
    {
        "ParameterKey": "Component",
        "ParameterValue": "$COMPONENT_NAME"
    },
    {
        "ParameterKey": "Stage",
        "ParameterValue": "$STAGE"
    }
]
EOF
    fi
  fi
fi

exit 0;
