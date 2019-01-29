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

title_docker() {
    doc_title << 'EOF'
         __           __
    ____/ /___  _____/ /_____  _____
   / __  / __ \/ ___/ //_/ _ \/ ___/
  / /_/ / /_/ / /__/ ,< /  __/ /
  \__,_/\____/\___/_/|_|\___/_/

EOF
    return 0
}

title_export() {
    doc_title << 'EOF'
                                __
    ___  _  ______  ____  _____/ /_
   / _ \| |/_/ __ \/ __ \/ ___/ __/
  /  __/>  </ /_/ / /_/ / /  / /_
  \___/_/|_/ .___/\____/_/   \__/
          /_/

EOF
    return 0
}

title_import() {
    doc_title << 'EOF'
      _                            __
     (_)___ ___  ____  ____  _____/ /_
    / / __ `__ \/ __ \/ __ \/ ___/ __/
   / / / / / / / /_/ / /_/ / /  / /_
  /_/_/ /_/ /_/ .___/\____/_/   \__/
             /_/

EOF
    return 0
}

title_install() {
    doc_title << 'EOF'
 // install //
EOF
    return 0
}

title_scp() {
    doc_title << 'EOF'
     ______________
    / ___/ ___/ __ \
   (__  ) /__/ /_/ /
  /____/\___/ .___/
           /_/

EOF
    return 0
}

title_sync() {
    doc_title << 'EOF'
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

EOF
}

title_update() {
    doc_title << 'EOF'
                     __      __
    __  ______  ____/ /___ _/ /____
   / / / / __ \/ __  / __ `/ __/ _ \
  / /_/ / /_/ / /_/ / /_/ / /_/  __/
  \__,_/ .___/\__,_/\__,_/\__/\___/
      /_/

EOF
    return 0
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

run_with_sudo() {
    local RUN_WITH_SUDO="${1}"; shift;
    sudo -s << EOF
PATH_BASE="${PATH_BASE}"
TRUE_HOME_DIR="${HOME_DIR}"
PREVIEW="${PREVIEW}"
source "${PATH_BASE}/src/init.sh"
${RUN_WITH_SUDO} "${@}"
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
    local DEST_DIR="${DEST_FILE%/*}"
    local DISPLAY_FILE_REF="${FILE_REF}"

    if [ -n "${GROUP/shared/}" ]; then
        DISPLAY_FILE_REF+=" (${GROUP})"
    fi

    # Link exists but doesn't point to the right file
    if [ -L "${DEST_FILE}" ] && ( [ ! -e "${DEST_FILE}" ] || [ "${SRC_FILE}" != "$(readlink ${DEST_FILE})" ] ); then
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
            backup_move "${DEST_DIR}" "${BACKUP}" "${FILE_NAME}" "${DISPLAY_FILE_REF}" || return 1
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

    if [ ! -d "${DEST_DIR}" ] && ! mkdir -p "${DEST_DIR}"; then
        echo_status "${term_fg_red}" "    Failed" "${DISPLAY_FILE_REF}"
        return 1
    fi

    # Create link and save status
    create_link "${SRC_FILE}" "${DEST_FILE}"
    local STATUS="${?}"

    if [ "${STATUS}" -eq 0 ]; then
        echo_status "${term_fg_green}" "   Created" "${DISPLAY_FILE_REF}"
    else
        echo_status "${term_fg_red}" "    Failed" "${DISPLAY_FILE_REF}"
    fi
    return "${STATUS}"
}

create_link() {
    local SRC_FILE="${1}"
    local DEST_FILE="${2}"

    if [ "${MSYS}" -eq 1 ]; then
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

export_dotfile() {
    local EXPORT_FILE="${1}"
    local REPO_DIR
    local REPO_FILE
    local FILE_REF

    if [ ! -e "${EXPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "   Missing" "${EXPORT_FILE}"
        return 1
    fi

    if [ ! -L "${EXPORT_FILE}" ]; then
        echo_status "${term_fg_green}" "  Restored" "${EXPORT_FILE}"
        return 1
    fi

    if truth "${PREVIEW}"; then
        echo_status "${term_fg_white}" "    Export" "${EXPORT_FILE}"
        return 0
    fi

    REPO_FILE="$(readlink "${EXPORT_FILE}")"
    if [ -z "${REPO_FILE}" ]; then
        error "Missing linked file for ${EXPORT_FILE}"
        return 1
    fi
    if [ "$(commonpath "${DOTFILES_DIR}" "${REPO_FILE}")" != "${DOTFILES_DIR}" ]; then
        error "Link must point to file inside ${DOTFILES_DIR}: ${REPO_FILE}"
        echo
        return 1
    fi
    FILE_REF="$(file_ref "${REPO_FILE}")"
    local DOTFILE_GROUP_DIR="${REPO_FILE/\/${FILE_REF}/}"
    REPO_DIR="${REPO_FILE%/*}"

    if ! rm "${EXPORT_FILE}"; then
        error "Failed to remove link ${EXPORT_FILE}"
        return 1
    fi
    if ! mv "${REPO_FILE}" "${EXPORT_FILE}"; then
        error "Failed to restore ${EXPORT_FILE}"
        return 1
    fi
    dotfile_git_add "${REPO_FILE}" || return 1

    if [ "${DOTFILE_GROUP_DIR}" != "${REPO_DIR}" ]; then
        cleanup_nested_dir "${DOTFILE_GROUP_DIR}" "${REPO_DIR}" || return 1
    fi

    echo_status "${term_fg_green}" "  Restored" "${EXPORT_FILE}"
}

import_dotfile() {
    local GROUP="${1}"
    local IMPORT_FILE="${2}"
    local FILE_REF="${2//${HOME_DIR}\//}"
    local DOTFILE_PATH="${DOTFILES_DIR}/${GROUP}/${FILE_REF}"
    local IMPORT_DIR="${IMPORT_FILE%/*}"
    local DOTFILES_DIR="${DOTFILE_PATH%/*}"

    if [ ! -e "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "   Missing" "${FILE_REF}"
        return 1
    fi
    if [ -e "${DOTFILE_PATH}" ]; then
        echo_status "${term_fg_green}" "  Imported" "${FILE_REF}"
        return 1
    fi
    if [ -L "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "      Link" "${FILE_REF}"
        return 1
    fi

    if truth "${PREVIEW}"; then
        echo_status "${term_fg_white}" "    Import" "${FILE_REF}"
        return 0
    fi

    if [ "${HOME_DIR}" != "${IMPORT_DIR}" ]; then
        ensure_nested_dir "${GROUP}" "${DOTFILES_DIR}" || return 1
    fi

    if ! mv "${IMPORT_FILE}" "${DOTFILE_PATH}"; then
        echo_status "${term_fg_red}" "    Failed" "${FILE_REF}"
        return 1
    fi

    if ! smart_link "${GROUP}" "${HOME_DIR}" "${DOTFILES_DIR}" "${IMPORT_DIR}" \
            "${BACKUP_DIR}" > /dev/null; then
        return 1
    fi
    echo_status "${term_fg_green}" "  Imported" "${FILE_REF}"

    dotfile_git_add "${DOTFILE_PATH}"
}

display_ensure_filesystem() {
    if [ "${PREVIEW}" -eq 1 ]; then
        info "Preview"
        echo
    fi

    local HEADING
    [ -n "${DOTFILES_REPO}" ] && HEADING="${DOTFILES_REPO}" || HEADING="${DOTFILES_DIR}"
    heading "Dotfiles ${term_fg_green}${HEADING}${term_reset}"

    display_ensure_dir "${DOTFILES_DIR}" "config" || return 1
    display_ensure_dir "${BACKUP_DIR}" "backup" || return 1
    [ "${sync_root}" -eq 1 ] && {
        display_ensure_dir "${ROOT_BACKUP_DIR}" "root backup" || return 1;
    }

    ensure_dotfiles_dir || return 1

    local SUCCESS=0
    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        display_ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" "${DOTFILE_GROUP} group" || SUCCESS=1
    done
    echo

    return "${SUCCESS}"
}

ensure_dotfiles_dir() {
    [ -d "${DOTFILES_DIR}" ] && return 0

    if [ -z "${DOTFILES_REPO}" ]; then
        error "Missing dotfiles repo config"
        return 1
    fi

    if ! clone_repo "${DOTFILES_REPO}" "${DOTFILES_DIR}"; then
        error "Failed to clone ${DOTFILES_REPO}"
        echo
        return 1
    fi

    [ -d "${DOTFILES_DIR}" ]
}

sync_config_to_home() {
    local BACKUP_DIR="${1%/}"
    local GROUP
    local SRC_DIR
    local EXCLUDE_NAMES=()
    local EXCLUDE_PATHS=()

    heading "Sync ${HOME_DIR}"

    if [ "${#DOTFILE_GROUP_LIST[@]}" = 0 ]; then
        echo "No repo groups available"
        return 1
    fi

    local SYNC_EXCLUDE
    for SYNC_EXCLUDE in "${SYNC_EXCLUDE_LIST[@]}"; do
        EXCLUDE_NAMES+=(-not -name "${SYNC_EXCLUDE}")
    done

    # Spin through groups syncing files
    # Skip files handled by a previous group
    for GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        SRC_DIR="${DOTFILES_DIR}/${GROUP}"
        cdd "${SRC_DIR}"

        while read -r -d $'\0' FILE; do
            # Skip dir if it contains a `${DOTFILE_MARKER}`
            if [ -d "${FILE}" ] && [ -f "${FILE}/${DOTFILE_MARKER}" ]; then
                [ "${DEBUG}" -gt 0 ] && echo "Skip nested dir: ${FILE}"
                continue
            fi

            # Skip file unless it's next to a `${DOTFILE_MARKER}`
            if [ -e "${FILE}" ] && [ ! -f "${FILE%/*}/${DOTFILE_MARKER}" ]; then
                [ "${DEBUG}" -gt 0 ] && echo "Skip non dotfile: ${FILE}"
                continue
            fi

            # Make sure we don't match this file again in another group
            EXCLUDE_PATHS+=(-not -path "${FILE}")

            smart_link "${GROUP}" "${SRC_DIR}" "${HOME_DIR}" "${BACKUP_DIR}" "${FILE/.\//}"
        done < <(find . -mindepth 1 "${EXCLUDE_NAMES[@]}" "${EXCLUDE_PATHS[@]}" -print0)
    done

    if [ "${#EXCLUDE_PATHS[@]}" -eq 0 ]; then
        info "No files in config repo, get started with \"dotfile import\""
    fi
    echo
}
