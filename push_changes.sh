#!/usr/bin/env bash
#/      --push_changes.sh--
#/  Pushes a commit to master while also incrementing the version based on
#/      the "level" of changes that have taken place and tagging that onto the commit.
#/
#/  Usage: push_changes.sh [options]
#/
#/  Options
#/      -v|--version                        Prints script name & version.
#/      -l|--level (patch|minor|major)      Sets level of update, to determine version bump (default: patch)
#/

# Script info
# ------------------------------------------
NAME="Repo Push Script"
VERSION="0.2.0"

# DEFAULT VARIABLES
# ------------------------------------------
DEBUG_LOG=1    # If 1, will print debug messages.
LEVEL=patch    # Set default level (this could be overwritten by input when common.sh is called).
CONFIG_PATH='' # Path to _auto_config.sh (should be passed in from client script. If empty, script fails

# SCRIPT SETUP
# ------------------------------------------
# Absolute path for this package
PPM_ABS_PATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
log "debug Found py-package-manager root directory at ${PPM_ABS_PATH}"

# Import common variables / functions, handle argument collection
log "debug Importing common variables..."
source ${PPM_ABS_PATH}/utils/common.sh

log "debug Reading in config file..."
if [[ -z ${CONFIG_PATH} ]]; then
    log "ERROR Please pass a path to the config.py file for your package"
    exit 1
else
    # Intake repo-specific variables
    # Get the dir of the CONFIG_PATH
    CONFIG_DIR="$(basename "${CONFIG_PATH}")"
    AUTO_CONFIG_PATH="${CONFIG_DIR}/_auto_config.sh"
    log "debug Sourcing in the auto_config file at ${AUTO_CONFIG_PATH}"
    source ${AUTO_CONFIG_PATH}
fi

# VERSION INCREMENTING
# ------------------------------------------
# Get highest tag number... if nothing found, start at 0.1.0
log "debug Attempting to grab latest tag version at repo ${REPO_DIR}"
CUR_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags) || echo "0.1.0"
log "debug Got current version of ${CUR_VERSION}"
NEW_VERSION="$(bump_version "${CUR_VERSION}")"

CONFIRM="Updating ${RED}${REPO_NAME}${RST} ${BLU}${CUR_VERSION}${RST} to ${BLU}${NEW_VERSION}${RST}."
read -p "Confirm (y/n): ${CONFIRM}" -n 1 -r
echo # (optional) move to a new line
if [[ ${REPLY} =~ ^[Yy]$ ]]; then
    # Get current hash and see if it already has a tag
    GIT_COMMIT=$(git -C ${REPO_DIR} rev-parse HEAD)
    NEEDS_TAG=$(git -C ${REPO_DIR} describe --contains ${GIT_COMMIT})

    # Only tag if no tag already (would be better if the git describe command above could have a silent option)
    if [[ -z "$NEEDS_TAG" ]]; then
        log "debug Tagged with ${NEW_VERSION} (Ignoring fatal:cannot describe - this means commit is untagged) "
        git -C ${REPO_DIR} tag ${NEW_VERSION}
        log "debug Pushing tag to ${MAIN_BRANCH}"
        git -C ${REPO_DIR} push --tags origin ${MAIN_BRANCH}
    else
        log "debug Already a tag on this commit"
    fi
else
    log "info Aborted tag."
fi

announce_section "Process completed"