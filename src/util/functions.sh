#!/usr/bin/env bash

ensure_dir() {
    if [ -d ${2} ]; then
        return 0
    fi
    mkdir -p ${2}
    local SUCCESS=${?}
    local MESSAGE="${1} ${2}"
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
    local ITEM=${3##*/}
    local LINK_MESSAGE="${SRC}/${ITEM} => ${DEST}/${ITEM}"

    if [ -L ${DEST}/${ITEM} ]; then
        info "Existing link ${LINK_MESSAGE}"
        return 0
    elif [ -e ${DEST}/${ITEM} ]; then
        if [ ! -d ${backup_dir} ]; then
            # mkdir ${backup_dir} || {


            #}
            if [ $? -eq 0 ]; then
                info "Link created ${LINK_MESSAGE}"
            else
                die "Failed to link ${LINK_MESSAGE}"
            fi
        fi
        die "No backup dir available for file ${DEST}/${ITEM}"
        mv ${DEST}/${ITEM} ${backup_dir} || die "Failed to backup file ${DEST}/${ITEM}"
    fi

    if [ ${WINDOWS} -eq 1 ]; then
        [ -d ${SRC}/${ITEM} ] && OPT="/D " || OPT=""

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
        info "Link created ${LINK_MESSAGE}"
    else
        die "Failed to link ${LINK_MESSAGE}"
    fi
}

doc_title() {
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo ${LINE}
    done;
    echo -n "${term_reset}"
}

heading() {
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${1}${term_reset}"
}

run_command() {
    local PATH_COMMAND="${PATH_BASE}/src/command/${1}.sh"
    [ -f ${PATH_COMMAND} ] || die "Command not found ${PATH_COMMAND}"
    source ${PATH_COMMAND}
    command_${1}
}
