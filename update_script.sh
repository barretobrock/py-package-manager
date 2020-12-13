#!/usr/bin/env bash
#/      --update_script.sh--
#/  Pulls changes from remote main branch and then updates the local python package
#/
#/  Usage: update_script.sh [options]
#/
#/  Options
#/      -s|--skip-deps                      Skips update of dependencies.
#/      -v|--version                        Prints script name & version.
#/

# Script info
# ------------------------------------------
NAME="Repo Update Script"
VERSION="0.2.0"

# DEFAULT VARIABLES
# ------------------------------------------
DEBUG_LOG=1    # If 1, will print debug messages.
LEVEL=patch    # Set default level (this could be overwritten by input when common.sh is called).
CONFIG_PATH='' # Path to _auto_config.sh (should be passed in from client script. If empty, script fails
SKIP_DEPS=0    # If 1, will skip dependenvy updates

# SCRIPT SETUP
# ------------------------------------------
# Absolute path for this package
PPM_ABS_PATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
echo "Found py-package-manager root directory at ${PPM_ABS_PATH}"

# Import common variables / functions, handle argument collection
echo "Importing common variables..."
source ${PPM_ABS_PATH}/utils/common.sh

log "debug Reading in config file..."
if [[ -z ${CONFIG_PATH} ]]; then
    # No file provided
    log "ERROR Please pass a path to the config.py file for your package"
    exit 1
elif [[ ! -f ${CONFIG_PATH} ]]; then
    # File provided but doesn't exist
    log "error The config.py file provided doesn't seem to exist at path: ${CONFIG_PATH}"
    exit 1
else
    # Intake repo-specific variables
    # Get the dir of the CONFIG_PATH
    CONFIG_DIR="$(dirname "${CONFIG_PATH}")"
    AUTO_CONFIG_PATH="${CONFIG_DIR}/_auto_config.sh"
    if [[ ! -f ${AUTO_CONFIG_PATH} ]]; then
        # Config file not made but config.py file exists. Run the python script to build out the bash variables
        log "debug auto_config.sh not found. Running Python script to build it."
        python3 ${CONFIG_PATH}
    fi
    log "debug Sourcing in the auto_config file at ${AUTO_CONFIG_PATH}"
    source ${AUTO_CONFIG_PATH}
fi

NODEPS_FLAG=''
if [[ "${SKIP_DEPS}" == "1" ]];
then
    log "debug Not installing dependencies"
    NODEPS_FLAG="--no-deps"
fi

# PULL CHANGES
# ------------------------------------------
announce_section "Pulling updates"
log "debug Pulling update on branch ${MAIN_BRANCH} from git repo ${REPO_DIR}"
(git -C ${REPO_DIR} pull origin ${MAIN_BRANCH})

# Py PACKAGE UPDATE
# ------------------------------------------
# Next install any custom dependencies (if any indicated)
if [[ ! -z ${DEP_LINKS} ]]; then
    log "info Updating custom dependencies"
    for i in "${DEP_LINKS[@]}"
    do
        ${VENV_PATH} -m pip install -e ${i} --upgrade ${NODEPS_FLAG}
    done
fi

# Then update the python package locally
log "info Beginning update of ${REPO_NAME}"
${VENV_PATH} -m pip install -e ${GIT_URL} --upgrade ${NODEPS_FLAG}

# CRON UPDATE
# ------------------------------------------
# Apply cronjob changes, if any.

CRON_DIR=${REPO_DIR}/crons
# Check if there's a cron dir in the repo
if [[ -d ${CRON_DIR} ]]; then
    log "debug Checking for crontab updates for ${HOSTNAME}"
    CRON_FILE=${CRON_DIR}/${HOSTNAME}.sh
    SUDO_CRON_FILE=${CRON_DIR}/su-${HOSTNAME}.sh
    [[ -f ${CRON_FILE} ]] && log "debug Applying cron file." && crontab ${CRON_FILE} || log "debug No cron file."
    [[ -f ${SUDO_CRON_FILE} ]] && log "debug Applying sudo cron file." && sudo crontab ${SUDO_CRON_FILE} || log "debug No sudo cron file."
    log "debug Cron updates completed"
else
    log "debug No cron folder in repo dir ${REPO_DIR}"
fi

announce_section "Process completed"
