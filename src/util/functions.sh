#!/usr/bin/env bash

ensure_dir() {
    local DIR=${1}
    local NAME=${2}
    local MESSAGE="${NAME} ${DIR}"
    if [ -z "${DIR}" ]; then
        warn "${NAME} not set"
        return 1
    fi
    if [ -d "${DIR}" ]; then
        info "Confirmed ${MESSAGE}"
        return 0
    fi
    mkdir -p ${DIR}
    local SUCCESS=${?}
    if [ ${SUCCESS} -eq 0 ]; then
        info "Created ${MESSAGE}"
    else
        warn "Failed to create ${MESSAGE}"
    fi
    return ${SUCCESS}
}

echo_win_path() {
    echo $(echo ${1} | sed "s|^${UNIX_HOME}|${WIN_HOME}|g" | sed 's|/|\\|g')
}

smart_link() {
    local SRC=${1%/}
    local DEST=${2%/}
    local BACKUP=${3%/}
    local ITEM=${4##*/}

    if [ -L "${DEST}/${ITEM}" ]; then
        echo_status ${term_fg_green} "         Linked" ${ITEM}
        return 0

    elif [ -e "${DEST}/${ITEM}" ]; then

        if ! truth ${WRITABLE}; then
            local BACKUP_COLOUR=${term_fg_yellow}
            if [ ! -d "${BACKUP}" ]; then
                BACKUP_COLOUR=${term_fg_red}
            fi
            echo_status ${BACKUP_COLOUR} "    Backup+Link" "${ITEM}"
            return 0
        fi

        if [ ! -d "${BACKUP}" ]; then
            echo_status "${term_fg_yellow}" "      No Backup" "${ITEM}"
            return 1
        fi
        if ! backup_move "${SRC}" "${BACKUP}" "${ITEM}"; then
            echo_status "${term_fg_red}" "  Backup Failed" "${ITEM}"
            return 1
        fi
        echo_status "${term_fg_yellow}" " Backup Created" "${ITEM}"

        # remove in a minute
        return
    fi

    if [ ! -d "${DEST}" ]; then
        echo_status "${term_fg_red}" "       Link Failed" ${ITEM}
        return 1
    fi
    if ! truth ${WRITABLE}; then
        echo_status "${term_fg_white}" "           Link" ${ITEM}
        return 0
    fi

    if [ ${WINDOWS} -eq 1 ]; then
        [ -d "${SRC}/${ITEM}" ] && OPT="/D " || OPT=""

        local WIN_SRC=$(echo_win_path ${SRC})
        local WIN_DEST=$(echo_win_path ${DEST})
        local CMD_C="mklink ${OPT}${WIN_DEST}\\${ITEM} ${WIN_SRC}\\${ITEM}"

        # windows link attempt
        cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
    else
        # unix link attempt
        ln -s ${SRC}/${ITEM} ${DEST}/${ITEM}
    fi

    # must be next command after the link attempt to catch the process result
    if [ $? -eq 0 ]; then
        echo_status ${term_fg_green} "   Link Created" ${ITEM}
        return 0
    else
        echo_status ${term_fg_red} "    Link failed" ${ITEM}
        return 1
    fi
}

doc_title() {
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo ${LINE}
    done;
    echo -n "${term_reset}"
}

dir_status() {
    local COLOUR
    local TITLE=${1}
    local DIR=${2}
    if [ -z "${DIR}" ]; then
        COLOUR="${term_fg_yellow}"
        DIR="not set"
    elif [ -d "${DIR}" ]; then
        COLOUR="${term_fg_green}"
    else
        COLOUR="${term_fg_red}"
    fi
    echo_status "${COLOUR}" "${TITLE}" "${DIR//$HOME/\~}"
}

echo_status() {
    local COLOUR=${1}
    local TITLE=${2}
    local MESSAGE=${3}
    echo "${TITLE}: ${term_bold}${COLOUR}${MESSAGE}${term_reset}"
}

heading() {
    local MESSAGE=${1}
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${MESSAGE//$HOME/\~}${term_reset}"
}

run_command() {
    local PATH_COMMAND="${PATH_BASE}/src/command/${1}.sh"
    [ -f "${PATH_COMMAND}" ] || die "Command not found ${PATH_COMMAND}"
    source ${PATH_COMMAND}
    command_${1}
}

backup_move() {
    local SRC=${1%/}
    local DEST=${2%/}
    local FILE=${3##*/}


    echo " src: ${SRC}"
    echo "dest: ${DEST}"
    echo "file: ${FILE}"
    echo "time: ${TIMESTAMP}"

    return 0
}
