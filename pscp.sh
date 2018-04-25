#! /usr/bin/env bash

usage() {
    echo "$0 [-f hostfile=hosts.txt] [-u username=$USER] [-i identity_file]"\
         "[-o outdir] [-e errdir] <local_file> <remote_file>"
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

    if [[ "$#" -ne 2 ]]; then
        echo "Incorrect number of arguments."
        usage "$0"
        return 1
    fi

    local -r local_file="$1"
    local -r remote_file="$2"

    parallel-scp \
        ${identity_file:+-O "IdentityFile=$identity_file"} \
        -l "${username:-$USER}" \
        -h "${hostfile:-hosts.txt}" \
        -o "${outdir:-out}" -e "${errdir:-err}" \
        "$local_file" \
        "$remote_file"
}

main "$@"
