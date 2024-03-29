#!/usr/bin/env bash
#/ ppm_main.sh - The primary file for PyPackageManager
#/      This script handles the commands used commonly to maintain a project.
#/
#/  Examples:
#/      >>> sh version_bump.sh              # The basic patch
#/      >>> sh version_bump.sh minor        # The sophisticated minor
#/      >>> sh version_bump.sh major        # The cultivated major
#/
#/  REQUIRED VARIABLES
#/      PROJECT -       the project name
#/      PY_LIB_NAME -   the library name in the project
#/      VENV_NAME -     virtual environment name in ~/venvs/
#/      MAIN_BRANCH -   name of the main branch in the repo (main|master)
#/ -------------------------------------
NAME="PyPackageManager"
VERSION='2.0.0'

# We need the absolute path var for this script
if [[ -z "${PPM_ABS_PATH}" ]]
then
    echo "Missing PPM_ABS_PATH variable. Please run ppm_init.sh to add the variable to your ~/.*shrc file."
    exit 1
fi

PPM_DIR_PATH="$(dirname ${PPM_ABS_PATH})"
COMMON_SH="${PPM_DIR_PATH}/utils/common.sh"
if [[ -f "${COMMON_SH}" ]]
then
    echo "Found py-package-manager root directory at ${PPM_DIR_PATH}"
else
    echo "Failed to find PPM directory/common_methods file. (Looked at ${PPM_DIR_PATH}) Aborting..."
    exit 1
fi

source ${COMMON_SH}

# These might not need to change from project to project
PROJECT_DIR="${HOME}/extras/${PROJECT}"
VERSION_FPATH="${PROJECT_DIR}/${PY_LIB_NAME}/__init__.py"
PYPROJECT_TOML_FPATH="${PROJECT_DIR}/pyproject.toml"
CHANGELOG_PATH="${PROJECT_DIR}/CHANGELOG.md"
VENV_PATH="${HOME}/venvs/${VENV_NAME}/bin/python3"

announce_section "Scanning for needed files..."
if [[ ! -d ${PROJECT_DIR} ]]
then
    make_log "error The project directory at path '${PROJECT_DIR}' was not found."
    exit 1
fi

NEEDED_FILES=(
    ${VERSION_FPATH}
    ${PYPROJECT_TOML_FPATH}
    ${CHANGELOG_PATH}
    ${VENV_PATH}
)
for p in "${NEEDED_FILES[@]}"; do
    if [[ ! -f "${p}" ]]
    then
        make_log "error Missing file at path: '${p}' Cannot proceed." && exit 1
    else
        make_log "debug Path found for file '${p}'."
    fi
done

announce_section "Handling command '${CMD}'..."
if [[ ${CMD} == 'bump' ]]
then
    # Get current version and calculate the new version based on level input
    make_log "debug Determining version bump..."
    bump_version $VERSION_FPATH $LEVEL

    # Build changelog string
    CHGLOG_STR="\ \n### [${NEW_VERSION}] - $(date +"%Y-%m-%d")\n#### Added\n#### Changed\n#### Deprecated\n#### Removed\n#### Fixed\n#### Security"

    CONFIRM_TXT=$(echo -e "Creating a ${GRN}RELEASE${RST}. Updating version '${BLU}${CUR_VERSION}${RST}' to '${RED}${NEW_VERSION}${RST}' in:\n\t - ${VERSION_FPATH} \n\t - ${PYPROJECT_TOML_FPATH} \n\t - ${CHANGELOG_PATH}\n ")

    # Confirm
    read -p $"Confirm (y/n): ${CONFIRM_TXT}" -n 1 -r
    echo # (optional) move to a new line

    if [[ ${REPLY} =~ ^[Yy]$ ]]
    then
        # 1. Apply new version & update date to file
        make_log "debug Applying new version, update date to __init__ file"
        # Logic: "Find line beginning with __version__, replace with such at file
        sed -i "s/^__version__.*/__version__ = '${NEW_VERSION}'/" ${VERSION_FPATH}
        sed -i "s/^__update_date__.*/__update_date__ = '$(date +"%Y-%m-%d_%H:%M:%S")'/" ${VERSION_FPATH}
        # 1.1. Add version to pyproject.toml
        sed -i "s/^version =.*/version = '${NEW_VERSION}'/" ${PYPROJECT_TOML_FPATH}
        # 2. Insert new section and link in CHANGELOG.md
        make_log "debug Inserting new area in CHANGELOG for version..."
        sed -i.bak "/__BEGIN-CHANGELOG__/a ${CHGLOG_STR}" ${CHANGELOG_PATH}
        make_log "info New version is ${RED}${NEW_VERSION}${RESET}"
        make_log "info To finish, fill in CHANGELOG details and then ${RED}make push${RESET}"
    else
        make_log "info Cancelled procedure"
    fi
elif [[ ${CMD} == 'pull' ]]
then
    make_log "debug Confirming branch..."
    confirm_branch ${MAIN_BRANCH}
    # Update procedure
    make_log "debug Pulling updates from remote ${RED}${MAIN_BRANCH}${RESET}..."
    (git -C $PROJECT_DIR pull origin ${MAIN_BRANCH})
    make_log "info Beginning update of ${PROJECT}..."
    ${VENV_PATH} -m pip install --upgrade --upgrade-strategy eager .
    if [[ -d "${PROJECT_DIR}/crons" ]]
    then
        CRON_DIR="${PROJECT_DIR}/crons"
        make_log "info Found a cron folder (${CRON_DIR}) - updating crons..."
        make_log "debug Checking for crontab updates for ${HOSTNAME}"
        CRON_FILE=${CRON_DIR}/${HOSTNAME}.sh
        SUDO_CRON_FILE=${CRON_DIR}/su-${HOSTNAME}.sh
        [[ -f ${CRON_FILE} ]] && make_log "debug Applying cron file." && crontab ${CRON_FILE} || make_log "debug No cron file."
        [[ -f ${SUDO_CRON_FILE} ]] && make_log "debug Applying sudo cron file." && sudo crontab ${SUDO_CRON_FILE} || make_log "debug No sudo cron file."
        make_log "debug Cron updates completed."
    fi
elif [[ ${CMD} == 'push' ]]
then
    make_log "debug Confirming branch..."
    confirm_branch ${MAIN_BRANCH}
    # Push to remote, tag
    make_log "debug Getting version..."
    get_version $VERSION_FPATH
    # First get the staged changes
    STAGED_ITEMS_TXT="$(git -C ${PROJECT_DIR} diff --shortstat)"
    CONFIRM_TXT=$(echo -e "Tagging the following changes with version ${RED}${CUR_VERSION}${RST} to ${RED}${MAIN_BRANCH}${RST}: \n\t${PRP}${STAGED_ITEMS_TXT}${RST} \n ")
    # Confirm
    read -p $"Confirm (y/n): ${CONFIRM_TXT}" -n 1 -r
    if [[ ${REPLY} =~ ^[Yy]$ ]]
    then
        # Get current hash and see if it already has a tag
        make_log "debug Grabbing commit"
        GIT_COMMIT=$(git -C ${REPO_DIR} rev-parse HEAD)
        make_log "debug Determining if needs tag"
        NEEDS_TAG=$(git -C ${REPO_DIR} describe --contains ${GIT_COMMIT})
        # Only tag if no tag already (would be better if the git describe command above could have a silent option)
        if [[ -z "$NEEDS_TAG" ]]; then
            make_log "debug Tagged with ${CUR_VERSION} (Ignoring fatal:cannot describe - this means commit is untagged) "
            git -C ${PROJECT_DIR} tag ${CUR_VERSION}
            make_log "debug Pushing tag to ${MAIN_BRANCH}"
            git -C ${PROJECT_DIR} push --tags origin ${MAIN_BRANCH}
        else
            make_log "debug Already a tag on this commit"
        fi
    else
        make_log "info Aborted tag."
    fi
else
    make_log "info No command matched (push|pull|bump)"
fi