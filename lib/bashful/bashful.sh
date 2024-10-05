commonpath() #{{{1
{
    # <doc:commonpath> {{{
    #
    # Gets the common path of the paths passed on stdin.
    # Alternatively, paths can be passed as arguments.
    #
    # Usage: commonpath [PATH...]
    #
    # </doc:commonpath> }}}

    local path

    # Make sure command line args go to stdin
    if (( $# > 0 )); then
        for path in "$@"; do
            echo "$path"
        done | commonpath
        return
    fi

    local prefix=$(
        while read -r; do
            echo "$(abspath "$REPLY")/"
        done | commonprefix
    )

    # We only want to break at path separators
    if [[ $prefix != */ ]]; then
        prefix=${prefix%/*}/
    fi

    # Only strip the trailing slash if it's not root (/)
    if [[ $prefix != / ]]; then
        prefix=${prefix%/}
    fi

    echo "$prefix"
}

abspath() #{{{1
{
    # <doc:abspath> {{{
    #
    # Gets the absolute path of the given path.
    # Will resolve paths that contain '.' and '..'.
    # Think readlink without the symlink resolution.
    #
    # Usage: abspath [PATH]
    #
    # </doc:abspath> }}}

    local path=${1:-$PWD}

    # Path looks like: ~user/...
    # Gods of bash, forgive me for using eval
    if [[ $path =~ ~[a-zA-Z] ]]; then
        if [[ ${path%%/*} =~ ^~[[:alpha:]_][[:alnum:]_]*$ ]]; then
            path=$(eval echo $path)
        fi
    fi

    # Path looks like: ~/...
    [[ $path == ~* ]] && path=${path/\~/$HOME}

    # Path is not absolute
    [[ $path != /* ]] && path=$PWD/$path

    path=$(squeeze "/" <<<"$path")

    local elms=()
    local elm
    local OIFS=$IFS; IFS="/"
    for elm in $path; do
        IFS=$OIFS
        [[ $elm == . ]] && continue
        if [[ $elm == .. ]]; then
            elms=("${elms[@]:0:$((${#elms[@]}-1))}")
        else
            elms=("${elms[@]}" "$elm")
        fi
    done
    IFS="/"
    echo "/${elms[*]}"
    IFS=$OIFS
}

squeeze() #{{{1
{
    # <doc:squeeze> {{{
    #
    # Removes leading/trailing whitespace and condenses all other consecutive
    # whitespace into a single space.
    #
    # Usage examples:
    #     echo "  foo  bar   baz  " | squeeze  #==> "foo bar baz"
    #
    # </doc:squeeze> }}}

    local char=${1:-[[:space:]]}
    sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}

trim() #{{{1
{
    # <doc:trim> {{{
    #
    # Removes all leading/trailing whitespace
    #
    # Usage examples:
    #     echo "  foo  bar baz " | trim  #==> "foo  bar baz"
    #
    # </doc:trim> }}}

    ltrim "$1" | rtrim "$1"
}

ltrim() #{{{1
{
    # <doc:ltrim> {{{
    #
    # Removes all leading whitespace (from the left).
    #
    # </doc:ltrim> }}}

    local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

rtrim() #{{{1
{
    # <doc:rtrim> {{{
    #
    # Removes all trailing whitespace (from the right).
    #
    # </doc:rtrim> }}}

    local char=${1:-[:space:]}
    sed "s%[${char//%/\\%}]*$%%"
}

commonprefix() #{{{1
{
    # <doc:commonprefix> {{{
    #
    # Gets the common prefix of the strings passed on stdin.
    #
    # Usage examples:
    #     echo -e "spam\nspace"   | commonprefix  #==> spa
    #     echo -e "foo\nbar\nbaz" | commonprefix  #==>
    #
    # </doc:commonprefix> }}}

    local i compare prefix

    if (( $# > 0 )); then
        local str
        for str in "$@"; do
            echo "$str"
        done | commonprefix
        return
    fi

    while read -r; do
        [[ $prefix ]] || prefix=$REPLY
        i=0
        unset compare
        while true; do
            [[ ${REPLY:$i:1} || ${prefix:$i:1} ]] || break
            [[ ${REPLY:$i:1} != ${prefix:$i:1} ]] && break
            compare+=${REPLY:$((i++)):1}
        done
        prefix=$compare
        echo "$prefix"
    done | tail -n1
}
