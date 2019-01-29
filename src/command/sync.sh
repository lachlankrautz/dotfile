#!/usr/bin/env bash
# shellcheck disable=SC2154

title_sync() {
    doc_title << 'EOF'
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

EOF
}

dotfile_command_sync() {
    title_sync
    display_ensure_filesystem
    sync_config_to_home "${BACKUP_DIR}"
    [ "${sync_root}" -eq 1 ] && run_with_sudo sync_config_to_home "${ROOT_BACKUP_DIR}"
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
