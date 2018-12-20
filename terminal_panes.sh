#! /usr/bin/env bash

# terminals_panes.sh creates a new tmux window and ssh'es into a number of
# hosts with one tmux pane per ssh connection. For example, if hosts.txt
# contains the following contents:
#
#   111.111.111.111
#   222.222.222.222
#   333.333.333.333
#
# then `./terminals_panes.sh -f hosts.txt` creates a tmux window with three
# panes. The first ssh'es into 111.111.111, the second ssh'es into
# 222.222.222, and the third ssh'es into 333.333.333.

set -euo pipefail

usage() {
    echo "$0 [-f hostfile=hosts.txt] [-u username=$USER] [-w window_name]" \
         "[-i identity_file]"
}

main() {
    while getopts ":hf:w:i:u:" opt; do
        case ${opt} in
            h )
                usage "$0"
                return 0
                ;;
            f )
                hostfile="$OPTARG"
                ;;
            w )
                window_name="$OPTARG"
                ;;
            i )
                identity_file="$OPTARG"
                ;;
            u )
                username="$OPTARG"
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

    if [[ "$#" -ne 0 ]]; then
        echo "Incorrect number of arguments provided."
        usage "$0"
        exit 1
    fi

    # Read hostfileinto hosts.
    hostfile=${hostfile:-"hosts.txt"}
    hosts=()
    while read host; do
        hosts+=("$host")
    done < "$hostfile"

    # Construct ssh commands.
    ssh_cmds=()
    for host in "${hosts[@]}"; do
        ssh_cmds+=("ssh ${identity_file:+-i $identity_file} -A ${username:-$USER}@$host")
    done

    # Create and layout panes.
    window_id="$(tmux new-window ${window_name:+-n $window_name} \
                    -P -F '#{session_name}:#{window_name}')"
    for ((i = 1; i < "${#ssh_cmds[@]}"; ++i)); do
        tmux split-window -t "${window_id}.0" -h -p 1
    done
    tmux select-layout -t "$window_id" even-vertical

    # Run ssh cmmand on each pane.
    for ((i = 0; i < "${#ssh_cmds[@]}"; ++i)); do
        tmux send-keys -t "${window_id}.$i" "${ssh_cmds[i]}" C-m
    done

    # Synchronize panes.
    tmux set-window-option -t "${window_id}" synchronize-panes on
}

main "$@"
