#!/usr/bin/env bash
#/ Description:
#/  - log: a simple terminal logger that timestamps messages
#/  - confirm_branch: a way to automatically check the current branch is the desired branch to perform an operation
#/  - bump_version: a means of taking a semver version and bumping it
#/ Usage:
#/  -- Logging
#/      - for INFO and up, load the file as such:
#/          >>> . common.sh
#/      - for DEBUG and up, load the file as such:
#/          >>> DEBUG_LOG=1
#/          >>> . common.sh
#/  -- Version Bumping
#/      - patch-level
#/          >>> NEW_VERSION=$(version_bump path/to/__init__.py)
#/          or
#/          >>> NEW_VERSION=$(version_bump path/to/__init__.py patch)
#/      - minor-level
#/          >>> NEW_VERSION=$(version_bump path/to/__init__.py minor)
#/      - major-level
#/          >>> NEW_VERSION=$(version_bump path/to/__init__.py major)

# ------------------------------------------
# COMMON COLOR CODES
# ------------------------------------------
# Color codes (Note instead of '\e' it's '\x1B', as Macs are weird and don't support \e by default
#   Update to above; apparently \033 also works? Linux is the only concern atm. Keeping this for future ref
GRN="\033[0;32m"
BLU="\033[0;34m"
YLW="\033[0;33m"
RED="\033[0;31m"
PRP="\033[1;35m"
RST="\033[0m"

# ------------------------------------------
# VARIABLES EXPECTED
# ------------------------------------------

CUR_VERSION=""
NEW_VERSION=""
CUR_UPDATE_DATE=""
NEW_UPDATE_DATE=""
CURRENT_BRANCH=""
TARGET_BRANCH=""

upper () {
  # Cast string to uppercase
  echo "${1}"|awk '{print toupper($0)}'
}

make_log () {
  # Logs steps
  # Example:
  #   >>> make_log "DEBUG doing something"
  MSG_TYPE=$(upper "$(echo $*|cut -d" " -f1)")
  MSG=$(echo "$*"|cut -d" " -f2-)
  # Determine log color
  case ${MSG_TYPE} in
      DEBUG)
        COLOR=${GRN}
        ;;
      INFO)
        COLOR=${BLU}
        ;;
      WARN)
        COLOR=${YLW}
        ;;
      ERROR)
        COLOR=${RED}
        ;;
      *)
        COLOR=${PRP}
        ;;
  esac
  # Print debug only when DEBUG_LOG is not 1
  [[ ${MSG_TYPE} == "DEBUG" ]] && [[ ${DEBUG_LOG} -ne 1 ]] && return
  [[ ${MSG_TYPE} == "INFO" ]] && MSG_TYPE="INFO " # one space for aligning
  [[ ${MSG_TYPE} == "WARN" ]] && MSG_TYPE="WARN " # as well

  # print to the terminal if we have one
  test -t 1 && printf "${COLOR} [${MSG_TYPE}]${RST} `date "+%Y-%m-%d_%H:%M:%S %Z"` [@${HOSTNAME}] [$$] ""${COLOR}${MSG}${RST}\n"
}

# This basically alerts the user that the log has been initiated
make_log "debug Logging initiated..."

confirm_branch () {
    CURRENT_BRANCH=$(git branch | sed -n '/\* /s///p')
    TARGET_BRANCH="${1:-master}"

    if [[ ! "${CURRENT_BRANCH}" == "${TARGET_BRANCH}" ]]
    then
        make_log "error Script aborted. Branch must be set on '${TARGET_BRANCH}'. Current branch is '${CURRENT_BRANCH}'" && exit 1 || return 1
    fi
}

get_version () {
    VERSION_PATH="${1}"
    make_log "debug Examining file at path ${VERSION_PATH}..."
    if [[ -f "${VERSION_PATH}" ]]; then
        CUR_VERSION=$(cat "${VERSION_PATH}" | grep -n '__version__.*' | awk -F "'|\"" {'print $2'})
    else
        make_log "error The file ${RED}${VERSION_PATH}${RESET} doesn't seem to exist. Exiting script..."
        exit 1
    fi
    make_log "info Got current version: ${CUR_VERSION} and level: ${LEVEL}"
}

bump_version () {
    #/ Takes in a filepath to the python file containing a line with __version__ = '...'
    #/      and a level =(patch, minor, or major)
    #/ Splits the version according to semver (major.minor.patch)
    #/ Increments the version based on level provided
    #/ Then outputs the new version
    VERSION_PATH="${1}"
    LEVEL=${2:-patch}
    make_log "debug Getting current version..."
    get_version ${VERSION_PATH}
    # Replace . with space so can split into an array
    make_log "debug Got: ${CUR_VERSION}"
    VERSION_BITS=(${CUR_VERSION//./ })

    # Get number parts and increase last one by 1
    VNUM1=${VERSION_BITS[0]}
    VNUM2=${VERSION_BITS[1]}
    VNUM3=${VERSION_BITS[2]}
    make_log "debug Broken out to: ${VNUM1} ${VNUM2} ${VNUM3}"

    if [[ "${LEVEL}" == "patch" || "${LEVEL}" == "hotfix" ]];
    then
        VNUM3=$((VNUM3+1))
    elif [[ "${LEVEL}" == "minor" ]];
    then
        VNUM2=$((VNUM2+1))
        VNUM3=0
    elif [[ "${LEVEL}" == "major" ]];
    then
        VNUM1=$((VNUM1+1))
        VNUM2=0
        VNUM3=0
    else
        make_log "error Invalid level selected. Please enter one of major|minor|patch." && exit 1
    fi
    #create new tag
    NEW_VERSION="${VNUM1}.${VNUM2}.${VNUM3}"
    make_log "debug New version: ${NEW_VERSION}"
}

announce_section () {
    # Makes sections easier to see in output
    SECTION_BRK="=============================="
    SECTION="${1}"
    COLOR=${2:-${BLU}}
    printf "${COLOR}${SECTION_BRK}\n${SECTION}\n${SECTION_BRK}${RST}\n"
}