#!/usr/bin/env bash
# shellcheck disable=SC2154

main_title() {
    doc_title << 'EOF'
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

EOF
}

usage() {
    main_title
    cat << EOF
${term_fg_yellow}Usage:${term_reset}
  dotfile [options] <command> <args>

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}               Display general usage or command help
  ${term_fg_green}-v, --version${term_reset}            Display version
  ${term_fg_green}-p, --preview${term_reset}            Preview changes without writing

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}                     Sync config dotfiles to home dir
  ${term_fg_green}import${term_reset} <pattern> [group] Import file into config group (default "shared")
  ${term_fg_green}export${term_reset} <pattern>         Export file back out of config
  ${term_fg_green}update${term_reset}                   Update config repo
  ${term_fg_green}ssh${term_reset}    <user@host>       Sync remote host
  ${term_fg_green}docker${term_reset} <container>       Sync docker container

EOF
}

cdd() {
    cd "${1}" || die "Unable to cd to ${1}"
}

# BSD and GNU sed required different params
sedi() {
    if sed --version >/dev/null 2>&1; then
        sed -i "${@}"
    else
        sed -i '' "${@}"
    fi
    return "${?}"
}

dotfile_git() {
    cdd "${DOTFILES_DIR}"
    git "${@}"
    local STATUS="${?}"
    cdd - > /dev/null
    return "${STATUS}"
}

dotfile_git_add() {
    local TO_ADD="${1}"
    local IGNORE_RULES
    if ! dotfile_git add "${TO_ADD}"; then
        error "Failed to stage ${TO_ADD} in git"

        # Check if failed because of ignore rules
        IGNORE_RULES="$(dotfile_git check-ignore -v "${TO_ADD}")"
        if [ -n "${IGNORE_RULES}" ]; then
            echo
            info "File ignored by git"
            echo "${IGNORE_RULES}"
        fi

        return 1
    fi

    return 0
}

clone_repo() {
    local GIT_REPO="${1}"
    local NAME="${2}"

    if ! git clone "${GIT_REPO}" "${NAME}"; then
        error "Failed to clone ${GIT_REPO}"
        return 1
    fi

    info "Cloned ${GIT_REPO} => ${NAME}"
    return 0
}

sudo_command() {
    local SUDO_COMMAND="${1}"; shift;
    sudo -s << EOF
PATH_BASE="${PATH_BASE}"
TRUE_HOME_DIR="${HOME_DIR}"
PREVIEW="${PREVIEW}"
source "${PATH_BASE}/src/init.sh"
${SUDO_COMMAND} "${@}"
EOF
}

ensure_not_root() {
    if [ "${IS_ROOT}" -eq 1 ]; then
        main_title
        error "Must not run as root"
        echo
        return 1
    fi
}

display_ensure_dir() {
    local DIR="${1}"
    local NAME="${2}"
    local MESSAGE="${NAME} ${DIR}"

    if [ -z "${DIR}" ]; then
        error "Dir param not set"
        return 1
    fi

    if [ -z "${NAME}" ]; then
        error "Name param not set"
        return 1
    fi

    if [ -d "${DIR}" ]; then
        info "Found ${MESSAGE}"
        return 0
    fi

    ensure_dir "${DIR}"
    local SUCCESS="${?}"

    if [ "${SUCCESS}" -eq 0 ]; then
        info "Created ${MESSAGE}"
    fi

    return "${SUCCESS}"
}

ensure_dir() {
    local DIR="${1}"

    if [ -z "${DIR}" ]; then
        error "Dir param not set"
        return 1
    fi

    if [ -d "${DIR}" ]; then
        return 0
    fi

    if ! mkdir -p "${DIR}"; then
        error "Failed to create ${DIR}"
        return 1
    fi

    return 0
}

ensure_file() {
    local FILE="${1}"

    [ -f "${FILE}" ] && return 0

    if ! touch "${FILE}"; then
        error "Failed to create ${FILE}"
        return 1
    fi

    return 0
}

# Create a link in a "smart" way
#
# - check for existing link
# - remove broken links
# - move existing file to backup dir
# - use `mklink` or `ln -s` depending on platform
# - support "preview" mode
#
smart_link() {
    local GROUP="${1%/}"
    local SRC="${2%/}"
    local DEST="${3%/}"
    local BACKUP="${4%/}"
    local FILE_REF="${5}"
    local FILE_NAME="${5##*/}"

    local SRC_FILE="${SRC}/${FILE_REF}"
    local DEST_FILE="${DEST}/${FILE_REF}"
    local DISPLAY_FILE_REF="${FILE_REF}"

    if [ -n "${GROUP/shared/}" ]; then
        DISPLAY_FILE_REF+=" (${GROUP})"
    fi

    # Link exists but doesn't point to the right file
    if [ -L "${DEST_FILE}" ] && [ ! -e "${DEST_FILE}" ]; then
        if [ "${PREVIEW}" -eq 1 ]; then
            echo_status "${term_fg_red}" "    Broken" "${DISPLAY_FILE_REF}"
            return 1
        else
            # Remove bad link
            rm "${DEST_FILE}"
        fi
    fi

    # Already linked
    if [ -L "${DEST_FILE}" ]; then
        echo_status "${term_fg_green}" "    Linked" "${DISPLAY_FILE_REF}"
        return 0
    fi

    # File already exists and needs to be backed up
    if [ -e "${DEST_FILE}" ]; then
        if [ ! -d "${BACKUP}" ]; then
            error "Missing backup dir: ${BACKUP}"
            return 1
        fi

        if [ "${PREVIEW}" -eq 1 ]; then
            echo_status "${term_fg_yellow}" "    Backup" "${DISPLAY_FILE_REF}"
        else
            backup_move "${DEST}" "${BACKUP}" "${FILE_NAME}" "${DISPLAY_FILE_REF}" || return 1
        fi
    fi

    # Preview
    if [ "${PREVIEW}" -eq 1 ]; then
        local COLOUR="${term_fg_white}"
        if [ ! -d "${DEST}" ]; then
            COLOUR="${term_fg_yellow}"
        fi
        echo_status "${COLOUR}" "      Link" "${DISPLAY_FILE_REF}"
        return 0
    fi

    if [ ! -d "${DEST}" ] && ! mkdir -p "${DEST}"; then
        echo_status "${term_fg_red}" "    Failed" "${DISPLAY_FILE_REF}"
        return 1
    fi

    # Create link and save status
    if [ "${WINDOWS}" -eq 1 ]; then
        [ -d "${SRC_FILE}" ] && OPT="/D " || OPT=""

        local WIN_SRC_FILE
        local WIN_DEST_FILE

        WIN_SRC_FILE="$(cygpath -w "${SRC_FILE}")"
        WIN_DEST_FILE="$(cygpath -w "${DEST_FILE}")"
        local CMD_C="mklink ${OPT}${WIN_DEST_FILE} ${WIN_SRC_FILE}"

        # Windows link attempt
        cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
    else
        # Unix link attempt
        ln -s "${SRC_FILE}" "${DEST_FILE}" > /dev/null 2>&1
    fi
    local STATUS="${?}"

    if [ "${STATUS}" -eq 0 ]; then
        echo_status "${term_fg_green}" "   Created" "${DISPLAY_FILE_REF}"
    else
        echo_status "${term_fg_red}" "    Failed" "${DISPLAY_FILE_REF}"
    fi
    return "${STATUS}"
}

backup_move() {
    local SRC="${1%/}"
    local BACKUP="${2%/}"
    local FILE="${3##*/}"
    local FILE_STATUS="${4}"

    local DEST="${SRC/${HOME_DIR}/${BACKUP}}"
    local BACKUP_FILE
    BACKUP_FILE="$(filename ${FILE})_${TIMESTAMP}$(extname ${FILE})"

    if [ ! -d "${DEST}" ]; then
        if ! mkdir -p "${DEST}"; then
            error "Unable to create backup dir ${DEST}"
            return 1
        fi
    fi

    # Move to backup dir
    if ! mv "${SRC}/${FILE}" "${DEST}/${BACKUP_FILE}"; then
        echo_status "${term_fg_red}" "    Backup" "${FILE_STATUS}"
        return 1
    fi

    echo_status "${term_fg_green}" "    Backup" "${FILE_STATUS/${FILE}/${BACKUP_FILE}}"
}

# Is this a nested dir
#
# - should not sync dir
# - should sync contents
# - marked by containing an ignore file
#
is_nested_dir() {
    local DIR="${1%/}"
    if [ ! -d "${DIR}" ]; then
        return 1
    fi

    if [ ! -f "${DIR}/${DOTFILE_MARKER}" ]; then
        return 1
    fi

    return 0
}

# Create deep dir structure with ignore files for nesting
ensure_nested_dir() {
    local GROUP="${1}"
    local DIR="${2%/}"
    local IGNORE_FILE

    if [ ! -d "${DIR}" ] && ! mkdir -p "${DIR}"; then
        error "Unable to create nested dir: ${DIR}"
        return 1
    fi

    local CURRENT_DIR
    local END_DIR="${DOTFILES_DIR}/${GROUP}"

    cdd "${DIR}"
    CURRENT_DIR="${PWD}"
    while [ "${CURRENT_DIR}" != "${END_DIR}" ]; do
        IGNORE_FILE="${CURRENT_DIR}/${DOTFILE_MARKER}"
        if [ ! -f "${IGNORE_FILE}" ]; then
            if ! touch "${IGNORE_FILE}"; then
                error "Unable to create ${IGNORE_FILE}"
                return 1
            fi
            dotfile_git_add "${IGNORE_FILE}" || return 1
        fi

        cdd ..
        CURRENT_DIR="${PWD}"
    done

    return 0
}

cleanup_nested_dir() {
    local DOTFILE_GROUP_DIR="${1%/}"
    local EXPORT_DIR="${2%/}"
    local NESTED_DIR

    if [ -z "${DOTFILE_GROUP_DIR}" ]; then
        error "Missing dotfile group dir param"
        return 1
    fi

    if [ ! -d "${DOTFILE_GROUP_DIR}" ]; then
        error "Dotfile group dir must be a directory: ${DOTFILE_GROUP_DIR}"
        return 1
    fi

    if [ -z "${EXPORT_DIR}" ]; then
        error "Missing export dir param"
        return 1
    fi

    if [ ! -d "${EXPORT_DIR}" ]; then
        error "Export dir must be a directory: ${EXPORT_DIR}"
        return 1
    fi

    cdd "${EXPORT_DIR}"
    NESTED_DIR="${PWD}"
    while [ "${NESTED_DIR}" != "${DOTFILE_GROUP_DIR}" ]; do
        IGNORE_FILE="${NESTED_DIR}/${DOTFILE_MARKER}"

        # Not a nested dir
        if [ ! -f "${IGNORE_FILE}" ]; then
            break
        fi

        # Still has dotfiles
        while IFS= read -r -d $'\0'; do
            if [ "${REPLY}" != "${IGNORE_FILE}" ]; then
                break 2
            fi
        done < <(listdir "${NESTED_DIR}" -print0)

        if ! rm "${IGNORE_FILE}"; then
            error "Failed to remove ${IGNORE_FILE}"
            return 1
        fi

        # Leave dir, delete it, reset NESTED_DIR
        cdd ..
        if ! rmdir "${NESTED_DIR}"; then
            error "Failed to remove ${NESTED_DIR}"
            return 1
        fi
        dotfile_git_add "${NESTED_DIR}" || return 1
        NESTED_DIR="${PWD}"
    done

    return 0
}

# shellcheck disable=SC2034
load_global_variables() {

    HELP="${HELP-0}"
    PREVIEW="${PREVIEW-0}"
    DEBUG="${DEBUG-0}"

    # Platform
    local UNAME
    UNAME="$(uname)"
    local LINUX=0
    local OSX=0
    WINDOWS=0
    if [ "${UNAME}" = "Linux" ]; then
        LINUX=1
    elif [ "${UNAME}" = "Darwin" ]; then
        OSX=1
    elif [[ "${UNAME}" =~ ^(MINGW|MSYS).*$ ]]; then
        WINDOWS=1
    fi

    # Home dir
    HOME_DIR=~
    TRUE_HOME_DIR="${TRUE_HOME_DIR-${HOME_DIR}}"
    [ "${LINUX}" -eq 1 ] && [ "${EUID}" -eq 0 ] && IS_ROOT=1 || IS_ROOT=0

    # Depends on loaded config
    ensure_config || return 1
    DOTFILE_MARKER=".dotfilemarker"
    DOTFILES_DIR="${config_dir/${HOME_DIR}\//${TRUE_HOME_DIR}/}"
    BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup"
    ROOT_BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup_root"
    SYNC_EXCLUDE_LIST=(".git" ".gitignore" ".DS_Store" "${DOTFILE_MARKER}")
    DOTFILES_REPO="${config_repo}"

    # Dotfile groups
    # Order is important
    DOTFILE_GROUP_LIST=()
    [ "${IS_ROOT}" -eq 1 ] &&  DOTFILE_GROUP_LIST+=("root")
    [ "${WINDOWS}" -eq 1 ] && DOTFILE_GROUP_LIST+=("windows")
    [ "${OSX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("osx")
    [ "${LINUX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("linux")
    DOTFILE_GROUP_LIST+=("shared")

    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" || return 1
        ensure_file "${DOTFILES_DIR}/${DOTFILE_GROUP}/${DOTFILE_MARKER}" || return 1
    done
}

ensure_config() {
    local PATH_CONFIG="${TRUE_HOME_DIR}/.config/dotfile"
    local FILE="${PATH_CONFIG}/config.ini"

    if [ ! -d "${PATH}" ]; then
        if ! mkdir -p "${PATH_CONFIG}"; then
            error "Unable to create config dir: ${PATH_CONFIG}"
            exit 1
        fi
    fi

    if [ ! -f "${FILE}" ]; then
        create_config "${FILE}"
        if [ ! -f "${FILE}" ]; then
            error "Unable to create config file: ${FILE}"
            exit 1
        fi
    fi

    cfg_parser "${FILE}"
    if ! cfg_section_dotfile; then
        error "Failed to load config: ${FILE}"
        exit 1
    fi

    return 0
}

create_config() {
    local FILE="${1}"

    if [ -z "${config_dir}" ]; then
        # shellcheck disable=SC2088
        config_dir="~/config"
    fi
    if [ -z "${config_repo}" ]; then
        config_repo=""
    fi

    cat << EOF >> ${FILE}
[dotfile]
;;; dir to clone config repo to
config_dir=${config_dir}

;;; config repo address
config_repo=${config_repo}

;;; sync dotfiles to root
sync_root=0
EOF
    sync
}

# TODO remove this whole function and use /*/ expansion to wildcard over the group
file_ref() {
    local FILE_REF_PATH="${1}"
    if [ -z "${FILE_REF_PATH}" ]; then
        error "Missing file ref param"
        return 1
    fi

    local DOTFILE_GROUP_PATTERN
    DOTFILE_GROUP_PATTERN="${DOTFILES_DIR}/($(implode "|" "${DOTFILE_GROUP_LIST[@]}"))/" || return 1
    local ESCAPED_PATTERN="${DOTFILE_GROUP_PATTERN//\//\\/}"

    echo "${FILE_REF_PATH}" | sed -E 's/'"${ESCAPED_PATTERN}"'//g'
}

doc_title() {
    local LINE=""
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
    elif [ -d "${DIR}" ] || [ -L "${DIR}" ]; then
        COLOUR="${term_fg_green}"
    else
        COLOUR="${term_fg_red}"
    fi
    echo_status "${COLOUR}" "${TITLE}" "${DIR}${EXTRA}"
}

implode() {
    local IFS="${1}"; shift;
    echo "${*}"
}

echo_status() {
    local COLOUR="${1}"
    local TITLE="${2}"
    local MESSAGE="${3}"
    echo "${TITLE} ${term_bold}${COLOUR}${MESSAGE}${term_reset}"
}

heading() {
    local MESSAGE="${1}"
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${MESSAGE}${term_reset}"
}
