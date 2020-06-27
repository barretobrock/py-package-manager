#!/usr/bin/env bash
#/      --update_script.sh--
#/  Pulls changes from remote master and then updates the local python package
#/
#/  Usage: update_script.sh [options]
#/
#/  Options
#/      -s|--skip-deps                      Skips update of dependencies.
#/      -v|--version                        Prints script name & version.
#/

# DEFAULT VARIABLES
# ============================================================================
NAME="Repo Update Script"
VERSION="0.1.0"
SKIP_DEPS=0
# Absolute path for this package
PPM_ABS_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Import common variables / functions
source ${PPM_ABS_PATH}/utils/common.sh
source ${PPM_ABS_PATH}/utils/yaml.sh
if [[ -z ${CONFIG_PATH} ]]; then
    echo "Please pass a path to the config.yaml file for your package"
    exit 1
fi

create_variables ${CONFIG_PATH}

NODEPS_FLAG=''
if [[ "${SKIP_DEPS}" == "1" ]];
then
    echo "Not installing dependencies"
    NODEPS_FLAG="--no-deps"
fi

announce_section "Pulling update from git repo"


# Next install any custom dependencies (if any indicated)
if [[ ! -z ${REPO_DEPS} ]]; then
    announce_section "Updating custom dependencies"
    for i in "${REPO_DEPS[@]}"
    do
        echo "${i}"
#        ${REPO_VENV} -m pip install -e ${i} --upgrade ${NODEPS_FLAG}
    done
fi

