DEBUG_LOG=1
PPM_DIR_PATH="$(
    cd "$(dirname "$0")" >/dev/null
    pwd -P
)"
COMMON_SH="${PPM_DIR_PATH}/utils/common.sh"
if [[ -f "${COMMON_SH}" ]]
then
    echo "Found py-package-manager common file at ${COMMON_SH}"
else
    echo "Failed to find PPM directory/common_methods file. (Looked at ${COMMON_SH}) Aborting..." && exit 1
fi

source ${COMMON_SH}

# Determine the shell
if [[ "${SHELL}" == "/usr/bin/zsh" ]]
then
  SHELLFILE=~/.zshrc
else
  SHELLFILE=~/.bashrc
fi

make_log "info Running initialization check for PPM for this machine..."
make_log "info Checking for PPM absolute path..."
if [[ -z "${PPM_ABS_PATH}" ]]
then
    make_log "debug PPM absolute path variable not found... Adding to bashrc"
    PPM_DIR_PATH="$(
        cd "$(dirname "$0")" >/dev/null
        pwd -P
    )"
    PPM_ABS_PATH="${PPM_DIR_PATH}/ppm_main.sh"

    make_log "debug Writing to ${SHELLFILE} and refreshing..."
    echo -e "\n#/ PyPackageManager\nexport PPM_ABS_PATH=${PPM_ABS_PATH}" >> ${SHELLFILE}
    . ${SHELLFILE}
fi

make_log "info Checking for preexisting aliases..."
IS_WRITE=false
CMDS=(
    ppmbump
    ppmpull
    ppmpush
)
for i in "${CMDS[@]}"; do
    if alias "$i" 2>/dev/null
    then
        make_log "debug ${i} is already an alias"
    else
        make_log "debug ${i} is _not_ already an alias. Writing to ${SHELLFILE}"
        if ! ${IS_WRITE}
        then
            IS_WRITE=true
        fi
        echo -e "#/ ${i} cmd\nalias ${i}='sh ${PPM_ABS_PATH} ${i:3}'" >> ${SHELLFILE}
    fi
done
if ${IS_WRITE}
then
    make_log "debug Refreshing ${SHELLFILE}..."
    . ${SHELLFILE}
fi