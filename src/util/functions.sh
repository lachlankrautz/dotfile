#!/usr/bin/env bash

sudo_command() {
    local SUDO_COMMAND="${1}"; shift;
    sudo -s << EOF
PATH_BASE="${PATH_BASE}"
TRUE_HOME_DIR="$(abspath ${HOME_DIR})"
WRITABLE="${WRITABLE}"
source "${PATH_BASE}/src/util/init.sh"
${SUDO_COMMAND} "${@}"
EOF
}

ensure_not_root() {
    if truth "${IS_ROOT}"; then
        main_title
        error "Must not run as root"
        echo
        exit 1
    fi
}

ensure_dir() {
    local DIR="${1}"
    local NAME="${2}"
    local MESSAGE="${NAME} ${DIR}"
    if [ -z "${DIR}" ]; then
        warn "${NAME} path not set"
        return 1
    fi
    if [ -d "${DIR}" ]; then
        info "Confirmed ${MESSAGE}"
        return 0
    fi
    mkdir -p "${DIR}"
    local SUCCESS=${?}
    if [ "${SUCCESS}" -eq 0 ]; then
        info "Created ${MESSAGE}"
    else
        warn "Failed to create ${MESSAGE}"
    fi
    return "${SUCCESS}"
}

win_path() {
    echo $(echo ${1} | sed "s|^${UNIX_HOME}|${WIN_HOME}|g" | sed 's|/|\\|g')
}

smart_link() {
    local GROUP="${1%/}"
    local IGNORE="${2%/}"
    local SRC="${3%/}"
    local DEST="${4%/}"
    local BACKUP="${5%/}"
    local FILE_NAME="${6##*/}"

    local SRC_FILE="${SRC}/${FILE_NAME}"
    local DEST_FILE="${DEST}/${FILE_NAME}"
    local FILE_STATUS="${DEST_FILE/${IGNORE}\//}"

    if [ ! -z "${GROUP}" ] && [ ! "${GROUP}" = "shared" ]; then
        FILE_STATUS="${FILE_STATUS} (${GROUP})"
    fi

    if [ -L "${DEST_FILE}" ]; then
        echo_status "${term_fg_green}" "         Linked" "${FILE_STATUS}"
        return 0

    elif [ -e "${DEST_FILE}" ]; then

        if ! truth ${WRITABLE}; then
            local BACKUP_COLOUR="${term_fg_yellow}"
            if [ ! -d "${BACKUP}" ]; then
                BACKUP_COLOUR="${term_fg_red}"
            fi
            echo_status "${BACKUP_COLOUR}" "Backup Required" "${FILE_STATUS}"
        else
            if [ ! -d "${BACKUP}" ]; then
                echo_status "${term_fg_yellow}" "      No Backup" "${FILE_STATUS}"
                return 1
            fi
            backup_move "${DEST}" "${BACKUP}" "${FILE_NAME}" || return 1
        fi
    fi

    if ! truth "${WRITABLE}"; then
        local COLOUR="${term_fg_white}"
        if [ ! -d "${DEST}" ]; then
            COLOUR="${term_fg_yellow}"
        fi
        echo_status "${COLOUR}" "  Link Required" "${FILE_STATUS}"
        return 0
    fi
    if [ ! -d "${DEST}" ]; then
        mkdir -p "${DEST}"
        if [ ! -d "${DEST}" ]; then
            echo_status "${term_fg_red}" "    Link Failed" "${FILE_STATUS}"
            return 1
        fi
    fi

    if [ "${WINDOWS}" -eq 1 ]; then
        [ -d "${SRC_FILE}" ] && OPT="/D " || OPT=""

        local WIN_SRC_FILE="$(win_path "${SRC_FILE}")"
        local WIN_DEST_FILE="$(win_path "${DEST_FILE}")"
        local CMD_C="mklink ${OPT}${WIN_DEST_FILE} ${WIN_SRC_FILE}"

        # Windows link attempt
        cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
    else
        # Unix link attempt
        ln -s "${SRC_FILE}" "${DEST_FILE}" > /dev/null 2>&1
    fi

    # must be next command after the link attempt to catch the process result
    if [ $? -eq 0 ]; then
        echo_status "${term_fg_green}" "   Link Created" "${FILE_STATUS}"
        return 0
    else
        echo_status "${term_fg_red}" "    Link failed" "${FILE_STATUS}"
        return 1
    fi
}

doc_title() {
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo "${LINE}"
    done;
    echo -n "${term_reset}"
}

dir_status() {
    local TITLE="${1}"
    local DIR="${2}"
    local EXTRA="${3}"

    local COLOUR=""
    if [ -z "${DIR}" ]; then
        COLOUR="${term_fg_yellow}"
        DIR="path not set"
    elif [ -d "${DIR}" ]; then
        COLOUR="${term_fg_green}"
    else
        COLOUR="${term_fg_red}"
    fi
    echo_status "${COLOUR}" "${TITLE}" "${DIR}${EXTRA}"
}

implode() {
    local IFS="${1}"; shift;
    echo "$*"
}

echo_status() {
    local COLOUR="${1}"
    local TITLE="${2}"
    local MESSAGE="${3}"
    if truth "${IS_ROOT}"; then
        MESSAGE="${MESSAGE//$TRUE_HOME_DIR/~}"
    else
        MESSAGE="${MESSAGE//$HOME/~}"
    fi
    echo "${TITLE}: ${term_bold}${COLOUR}${MESSAGE}${term_reset}"
}

heading() {
    local MESSAGE="${1}"
    if [ ! "${HOME}" = "/root" ]; then
        MESSAGE="${MESSAGE//$HOME/~}"
    fi
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${MESSAGE}${term_reset}"
}

backup_move() {
    local SRC=${1%/}
    local DEST=${2%/}
    local FILE=${3##*/}
    local BACKUP_FILE="$(filename ${FILE})_${TIMESTAMP}$(extname ${FILE})"

    mv "${SRC}/${FILE}" "${DEST}/${BACKUP_FILE}"

    local SUCCESS="${?}"
    if [ ${SUCCESS} -eq 0 ]; then
        echo_status "${term_fg_yellow}" " Backup Created" "${BACKUP_FILE}"
    else
        echo_status "${term_fg_red}" "  Backup Failed" "${FILE}"
    fi
    return "${SUCCESS}"
}

main_title() {
    doc_title << 'EOF'
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

EOF
}
