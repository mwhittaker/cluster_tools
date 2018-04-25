#! /usr/bin/env bash

# tmux_tail.sh runs 'tail -f' on a set of files with every invocation in its
# own tmux pane. For example, `tmux_tail.sh a b c` creates a new tmux window
# with three panes. The first invokes `tail -f a`, the second invokes `tail -f
# b`, and the third invokes `tail -f c`. The `-w` option can be used to name
# the window.
#
#   $ # Tail every log file in out/ in a window called out
#   $ ./tmux_tail.sh -w out out/*.log

set -euo pipefail

usage() {
    echo "$0 [-w window_name] <file>..."
}

main() {
    while getopts ":hw:" opt; do
        case ${opt} in
            h )
                usage "$0"
                return 0
                ;;
            w )
                window_name="$OPTARG"
                echo "$window_name"
                ;;
            \? )
                usage "$0"
                return 1
                ;;
            : )
                echo "$OPTARG reqiures an argument."
                usage "$0"
                return 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    # http://stackoverflow.com/a/13864829/3187068
    if [[ -z ${TMUX+dummy} ]]; then
        echo "ERROR: you must run this script while in tmux."
        return 1
    fi

    # We need at least 1 argument.
    if [[ "$#" -eq 0 ]]; then
        echo "Incorrect number of arguments provided."
        usage "$0"
        return 1
    fi

    # Create and layout panes.
    tmux new-window ${window_name:+"-n $window_name"}
    for ((i = 1; i < "$#"; ++i)); do
        tmux split-window -h -p 99
    done
    tmux select-layout even-vertical

    # Run tail on each pane.
    args=("$@")
    for ((i = 0; i < "$#"; ++i)); do
        tmux send-keys -t "$i" "tail -f ${args[i]}" C-m
    done

    # Synchronize panes.
    tmux set-window-option synchronize-panes on
}

main "$@"
