#! /usr/bin/env bash

# pssh.sh is a simple wrapper around parallel-ssh.
#
#   $ # Run foo.sh on all the machines listed in hosts.txt.
#   $ ./pssh -f hosts.txt -u ec2-user -i ~/.ssh/key.pem foo.sh

set -euo pipefail

usage() {
    echo "$0 [-f hostfile=hosts.txt] [-u username=$USER] [-i identity_file]" \
         "[-o outdir] [-e errdir] <script>"
}

main() {
    while getopts ":hf:i:u:o:e:" opt; do
        case ${opt} in
            h )
                usage "$0"
                return 0
                ;;
            f )
                hostfile="$OPTARG"
                ;;
            i )
                identity_file="$OPTARG"
                ;;
            u )
                username="$OPTARG"
                ;;
            o )
                outdir="$OPTARG"
                ;;
            e )
                errdir="$OPTARG"
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

    if [[ "$#" -ne 1 ]]; then
        echo "Incorrect number of arguments provided."
        usage "$0"
        exit 1
    fi

    local -r script="$1"
    parallel-ssh \
        -x "${identity_file:+-i $identity_file} -A" \
        -l "${username:-$USER}" \
        -h "${hostfile:-hosts.txt}" \
        -t 0 \
        -o "${outdir:-out}" -e "${errdir:-err}" \
        -I < "$script"
}

main "$@"
