#!/usr/bin/env bash
# shellcheck disable=SC2154

usage() {
    main_title
    local GROUP_LIST_DISPLAY
    GROUP_LIST_DISPLAY="$(implode "|" "${DOTFILE_GROUP_LIST[@]}" | sed 's/|shared//')"
    cat << EOF
${term_fg_yellow}Usage:${term_reset}
  dotfile [options] <command> <args>

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}         Display general usage or command help
  ${term_fg_green}--version${term_reset}          Display version
  ${term_fg_green}-p, --preview${term_reset}      Preview changes without writing
  ${term_fg_green}-g, --group${term_reset}        Use platform group instead of "shared" ie. (${GROUP_LIST_DISPLAY})
  ${term_fg_green}-v, --verbose${term_reset}      Set verbosity level

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}               Sync config dotfiles to home dir
  ${term_fg_green}import${term_reset} <file...>   Import file into config
  ${term_fg_green}export${term_reset} <file...>   Export file back out of config
  ${term_fg_green}update${term_reset}             Update config repo
  ${term_fg_green}config${term_reset}             Edit config file

EOF
}

# Empty call
dotfile_() {
    usage
}

# Bad call
dotfile_call_() {
    usage
    return 1
}

dotfile_option_v() {
    dotfile_option_verbose "${@}"
}
dotfile_option_verbose() {
    verbose 1
    dispatch dotfile "$@"
}

dotfile_option_version() {
    echo "Version ${term_fg_yellow}2.0.0${term_reset}"
}

dotfile_option_h() {
    dotfile_option_help "${@}"
}
dotfile_option_help() {
    export HELP=1
    dispatch dotfile "${@}"
}

dotfile_option_p() {
    dotfile_option_preview "${@}"
}
dotfile_option_preview() {
    export PREVIEW=1
    dispatch dotfile "$@"
}

dotfile_option_g() {
    dotfile_option_group "${@}"
}
dotfile_option_group() {
    export ACTIVE_GROUP="${1}"
    local GROUP
    local FOUND=0
    for GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        if [ "${ACTIVE_GROUP}" = "${GROUP}" ]; then
            FOUND=1
        fi
    done
    if [ "${FOUND}" -eq 0 ]; then
        error "Invalid group: ${ACTIVE_GROUP}"
        return 1
    fi
    shift

    dispatch dotfile "${@}"
}

dotfile_command_config() {
    local CONFIG_FILE="${TRUE_HOME_DIR}/.config/dotfile/config.ini"

    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "Missing config file: ${CONFIG_FILE}"
        reutrn 1
    fi

    ${EDITOR:-vi} "${CONFIG_FILE}"
}

dotfile_command_export() {
    title_export

    if [ -z "${*}" ]; then
        echo "Missing files to export"
        echo
        return 1
    fi

    if [ "${PREVIEW}" -eq 1 ]; then
        info "Preview"
        echo
    fi

    heading "Export ${term_fg_blue}$(implode " " "${@}")${term_reset}"

    local FILES=("${@}")
    local FILE
    local STATUS=0
    for FILE in "${FILES[@]}"; do
        export_dotfile "${FILE}" || STATUS=1
    done
    return "${STATUS}"
}

dotfile_command_import() {
    if [ -z "${*}" ]; then
        echo "Missing files to import"
        echo
        return 1
    fi

    title_import

    if [ "${PREVIEW}" -eq 1 ]; then
        info "Preview"
        echo
    fi

    heading "Import ${term_fg_blue}$(implode " " "${@}")${term_reset} into ${term_fg_blue}${DOTFILES_DIR}/${ACTIVE_GROUP}${term_reset}"

    local FILES=("${@}")
    local FILE
    local STATUS=0
    for FILE in "${FILES[@]}"; do
        import_dotfile "${ACTIVE_GROUP}" "${FILE}" || STATUS=1
    done
    return "${STATUS}"
}

dotfile_command_install() {
    title_install

    create_link "${PATH_BASE}/bin/dotfile" /usr/local/bin/dotfile 1 || return 1
}

dotfile_command_sync() {
    title_sync
    display_ensure_filesystem || return 1
    sync_config_to_home || return 1
    [ "${sync_root}" -eq 1 ] && run_with_sudo sync_config_to_home
}

dotfile_command_update() {
    title_update

    if ! dotfile_git diff-index --quiet HEAD --; then
        info "Local config changes detected"
        echo

        dotfile_git status
        echo

        question -p "Stage and commit changes?" -d "yes" || return 1
        dotfile_git commit -p || return 1
    fi

    heading "Updating ${DOTFILES_REPO}"
    echo

    info "git pull --rebase"
    dotfile_git pull --rebase
    echo

    info "git push"
    dotfile_git push
    echo

    info "git status"
    dotfile_git status
    echo
}

dotfile_command_test() {
    :
}
