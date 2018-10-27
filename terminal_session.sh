#! /usr/bin/env bash

# terminal_session.sh creates a new tmux session and ssh'es into a number of
# hosts with one tmux window per ssh connection. For example, if hosts.txt
# contains the following contents:
#
#   111.111.111.111
#   222.222.222.222
#   333.333.333.333
#
# then `./terminal_session.sh -f hosts.txt` creates a tmux session with three
# panes.  The first ssh'es into 111.111.111, the second ssh'es into
# 222.222.222, and the third ssh'es into 333.333.333.

set -euo pipefail

usage() {
    echo "$0 [-f hostfile=hosts.txt] [-u username=$USER] [-s session_name]" \
         "[-i identity_file]"
}

main() {
    while getopts ":hf:s:i:u:" opt; do
        case ${opt} in
            h )
                usage "$0"
                return 0
                ;;
            f )
                hostfile="$OPTARG"
                ;;
            s )
                session_name="$OPTARG"
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

    hostfile=${hostfile:-"hosts.txt"}
    session_name=${session_name:-"terminals"}

    if [[ "$#" -ne 0 ]]; then
        echo "Incorrect number of arguments provided."
        usage "$0"
        exit 1
    fi

    # Read hostfileinto hosts.
    hosts=()
    while read host; do
        hosts+=("$host")
    done < "$hostfile"

    # Construct ssh commands.
    ssh_cmds=()
    for host in "${hosts[@]}"; do
        ssh_cmds+=("ssh ${identity_file:+-i $identity_file} -A ${username:-$USER}@$host")
    done

    # Create the new session.
    tmux new-session -s "$session_name" -d

    # Create and name the appropriate number of windows.
    tmux rename-window -t "$session_name:" ${hosts[0]}
    for ((i = 1; i < "${#hosts[@]}"; ++i)); do
        tmux new-window -t "$session_name:" -n "${hosts[i]}"
    done

    # Run ssh command on each pane.
    for ((i = 0; i < "${#ssh_cmds[@]}"; ++i)); do
        tmux send-keys -t "$session_name:$i" "${ssh_cmds[i]}" C-m
    done
}

main "$@"
