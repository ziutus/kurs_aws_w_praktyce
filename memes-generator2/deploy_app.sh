#! /bin/bash
set -u
set -e 

STEP=12

[ $STEP -eq 10 ] && application/commands/upload-cw-config.sh && STEP=11
[ $STEP -eq 11 ] && application/commands/upload-srv-config.sh && STEP=12
[ $STEP -eq 11 ] && application/commands/upload-pictures.sh && STEP=13


exit 0