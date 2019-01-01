#!/usr/bin/env bash

# Dotfile dependencies can take a while to load (especially with msys2)
# Source this file to cache the slower portions
#
# Add to .bashrc so dotfile runs faster
#
# ```bash
# source dotfile/cache/source-me.sh
# ```

set -a
echo "Caching terminfo"
source "${BASH_SOURCE%/*}/../lib/bashful/bashful-terminfo"
set +a
