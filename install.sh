#!/usr/bin/env bash
#/ Handles installing the client-side scripts at the directory of choice

REPO_DIR="${1}"
if [[ ! -d ${REPO_DIR} ]];
then
    echo "Not a known directory: ${REPO_DIR}"
else
    echo "Copying push & update scripts to target directory: ${REPO_DIR}"
    cp client_scripts/client_push_changes.sh ${REPO_DIR}/push_changes.sh
    cp client_scripts/client_update_script.sh ${REPO_DIR}/update_script.sh
fi
