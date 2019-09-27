#!/usr/bin/env bash
# shellcheck disable=SC1090

# Dependencies can take a while to load (especially with msys2)
# Source this file to cache them
#
# Add to `.bashrc`
#
#   ```bash
#   source <path-to-dotfile>/cache/source-me.sh
#   ```

# source expensive dependencies on first run only
dotfile() {
    set -a
    source "${BASH_SOURCE%/*}/../lib/bashful/bashful-terminfo"
    set +a

    command dotfile "${@}"
    unset -f dotfile
}
