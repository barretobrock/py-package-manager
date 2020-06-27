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

# GIT PULL
# ============================================================================
announce_section "Pulling update from git repo"
(git -C ${REPO_DIR} pull origin master)

# PY PACKAGE UPDATE
# ============================================================================
# First, make sure PyYAML is installed
# If not, we'll need to install before actually installing the package(s)
PKG_EXISTS=$(${REPO_VENV} -m pip list | grep -F PyYAML)
if [[ -z ${PKG_EXISTS} ]]; then
    echo "Package pyyaml doesn't exist in selected virtualenv. Installing before installing ${REPO_NAME}"
    ${REPO_VENV} -m pip install PyYAML==5.3.1
fi

# Next install any custom dependencies (if any indicated)
if [[ ! -z ${REPO_DEPS} ]]; then
    announce_section "Updating custom dependencies"
    for i in "${REPO_DEPS[@]}"
    do
        ${REPO_VENV} -m pip install -e ${i} --upgrade ${NODEPS_FLAG}
    done
fi

# Then update the python package locally
announce_section "Beginning update of ${REPO_NAME}"
${REPO_VENV} -m pip install -e ${REPO_GIT_URL} --upgrade ${NODEPS_FLAG}

# CRON UPDATE
# ============================================================================
# Apply cronjob changes, if any.

CRON_DIR=${REPO_DIR}/crons
# Check if there's a cron dir in the repo
if [[ -d ${CRON_DIR} ]]; then
    announce_section "Checking for crontab updates for ${HOSTNAME}"
    CRON_FILE=${CRON_DIR}/${HOSTNAME}.sh
    SUDO_CRON_FILE=${CRON_DIR}/su-${HOSTNAME}.sh
    [[ -f ${CRON_FILE} ]] && echo "Applying cron file." && crontab ${CRON_FILE} || echo "No cron file."
    [[ -f ${SUDO_CRON_FILE} ]] && echo "Applying sudo cron file." && sudo crontab ${SUDO_CRON_FILE} || echo "No sudo cron file."
    announce_section "Cron updates completed"
else
    echo "No cron folder in repo dir ${REPO_DIR}"
fi

announce_section "Process completed"
