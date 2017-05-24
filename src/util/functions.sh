#!/usr/bin/env bash

ensure_dir() {
    local DIR="${1}"
    local NAME="${2}"
    local MESSAGE="${NAME} ${DIR}"
    if [ -z "${DIR}" ]; then
        warn "${NAME} not set"
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

echo_win_path() {
    echo $(echo ${1} | sed "s|^${UNIX_HOME}|${WIN_HOME}|g" | sed 's|/|\\|g')
}

smart_link() {
    local SRC="${1%/}"
    local SUB_DIR="${2%/}"
    local DEST="${3%/}"
    local BACKUP="${4%/}"
    local ITEM="${5##*/}"

    local SRC_ITEM="${SRC}/${SUB_DIR}"
    SRC_ITEM="${SRC_ITEM%/}/${ITEM}"
    local DEST_ITEM="${DEST}/${ITEM}"
    local ITEM_STATUS="${ITEM}"

    if [ ! -z "${SUB_DIR}" ] && [ ! "${SUB_DIR}" = "shared" ]; then
        ITEM_STATUS="${ITEM_STATUS} (${SUB_DIR})"
    fi

    if [ -L "${DEST_ITEM}" ]; then
        echo_status "${term_fg_green}" "         Linked" "${ITEM_STATUS}"
        return 0

    elif [ -e "${DEST_ITEM}" ]; then

        if ! truth ${WRITABLE}; then
            local BACKUP_COLOUR="${term_fg_yellow}"
            if [ ! -d "${BACKUP}" ]; then
                BACKUP_COLOUR="${term_fg_red}"
            fi
            echo_status "${BACKUP_COLOUR}" "    Backup+Link" "${ITEM_STATUS}"
            return 0
        fi

        if [ ! -d "${BACKUP}" ]; then
            echo_status "${term_fg_yellow}" "      No Backup" "${ITEM_STATUS}"
            return 1
        fi
        backup_move "${DEST}" "${BACKUP}" "${ITEM}" || return 1
    fi

    if ! truth "${WRITABLE}"; then
        local COLOUR="${term_fg_white}"
        if [ ! -d "${DEST}" ]; then
            COLOUR="${term_fg_red}"
        fi
        echo_status "${COLOUR}" "           Link" "${ITEM_STATUS}"
        return 0
    fi
    if [ ! -d "${DEST}" ]; then
        echo_status "${term_fg_red}" "    Link Failed" "${ITEM_STATUS}"
        return 1
    fi

    if [ "${WINDOWS}" -eq 1 ]; then
        [ -d "${SRC_ITEM}" ] && OPT="/D " || OPT=""

        local WIN_SRC_ITEM=$(echo_win_path "${SRC_ITEM}")
        local WIN_DEST_ITEM=$(echo_win_path "${DEST_ITEM}")
        local CMD_C="mklink ${OPT}${WIN_DEST_ITEM} ${WIN_SRC_ITEM}"

        # Windows link attempt
        cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
    else
        # Unix link attempt
        ln -s "${SRC_ITEM}" "${DEST_ITEM}" > /dev/null 2>&1
    fi

    # must be next command after the link attempt to catch the process result
    if [ $? -eq 0 ]; then
        echo_status "${term_fg_green}" "   Link Created" "${ITEM_STATUS}"
        return 0
    else
        echo_status "${term_fg_red}" "    Link failed" "${ITEM_STATUS}"
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
    local COLOUR
    local TITLE="${1}"
    local DIR="${2}"
    local EXTRA="${3}"
    if [ -z "${DIR}" ]; then
        COLOUR="${term_fg_yellow}"
        DIR="not set"
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
    echo "${TITLE}: ${term_bold}${COLOUR}${MESSAGE//$HOME/\~}${term_reset}"
}

heading() {
    local MESSAGE="${1}"
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${MESSAGE//$HOME/\~}${term_reset}"
}

run_command() {
    local COMMAND="${1}"; shift
    local PATH_COMMAND="${PATH_BASE}/src/command/${COMMAND}.sh"
    [ -f "${PATH_COMMAND}" ] || die "Command not found ${PATH_COMMAND}"
    source "${PATH_COMMAND}"
    command_${COMMAND} "$@"
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
