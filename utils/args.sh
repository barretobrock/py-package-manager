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