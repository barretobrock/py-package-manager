#!/usr/bin/env bash
# ------------------------------------------
# COMMON VARIABLES / FUNCTIONS
# ------------------------------------------
# Color codes
GRN="\e[32m"
BLU="\e[34m"
YLW="\e[33m"
RED="\e[31m"
PRP="\e[1;35m"
RST="\e[0m"

upper () {
  # Cast string to uppercase
  echo "${1}"|awk '{print toupper($0)}'
}

log () {
  # Logs steps
  # Example:
  #   >>> log "DEBUG doing something"
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
log "debug logging initiated..."

contains () {
    # Checks if the variable ($2) is in the space-separated list provided ($1)
    LIST=$1
    VAR=$2
    [[ "${LIST}" =~ (^|[[:space:]])"${VAR}"($|[[:space:]]) ]];
}

confirm_branch () {
    CURRENT_BRANCH=$(git branch | sed -n '/\* /s///p')
    TARGET_BRANCH="${1:-master}"

    if [[ ! "${CURRENT_BRANCH}" == "${TARGET_BRANCH}" ]]
    then
        log "error Script aborted. Branch must be set on '${TARGET_BRANCH}'. Current branch is '${CURRENT_BRANCH}'" && exit 1 || return 1
    fi
}

bump_version () {
    VERSION="${1}"
    log "info Got version: ${VERSION} and level: ${LEVEL}"
    # Replace . with space so can split into an array
    VERSION_BITS=(${VERSION//./ })
    # Get number parts and increase last one by 1
    VNUM1=${VERSION_BITS[0]}
    VNUM2=${VERSION_BITS[1]}
    VNUM3=${VERSION_BITS[2]}

    if [[ "${LEVEL}" == "patch" ]];
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
    fi
    #create new tag
    NEW_TAG="${VNUM1}.${VNUM2}.${VNUM3}"
    log "debug New version: ${NEW_TAG}"
    echo "${NEW_TAG}"
}

announce_section () {
    # Makes sections easier to see in output
    SECTION_BRK="=============================="
    SECTION="${1}"
    COLOR=${2:-${BLU}}
    printf "\n${COLOR}${SECTION_BRK}\n${SECTION}\n${SECTION_BRK}${RST}\n"
}

log "DEBUG parsing arguments..."
arg_parse() {
    # Parses arguments from command line
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case ${key} in
            -s|--skip-deps)
                log "DEBUG received skip dependency argument. Setting to TRUE."
                SKIP_DEPS=1
                shift # past argument
                ;;
            -c|--config)
                CONFIG_PATH=${2}
                log "DEBUG received configuration path argument: ${CONFIG_PATH}"
                shift # past argument
                shift # past value
                ;;
            -v|--version)   # Print script name & version
#                echo "${NAME} ${VERSION}"
                announce_section "${NAME}\n${VERSION}"
                exit 0
                ;;
            -l|--level)
                LEVEL=${2:-patch}
                log "DEBUG received level argument: ${LEVEL}"
                shift # past argument
                shift # past value
                ;;
            *)    # unknown option
                POSITIONAL+=("$1") # save it in an array for later
                shift # past argument
                ;;
    esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters
    # Check for unknown arguments passed in (if positional isn't empty)
    [[ ! -z "${POSITIONAL}" ]] && echo "Unknown args passed: ${POSITIONAL[@]}" && exit 1
}

# Collect arguments when this is called
arg_parse "$@"
