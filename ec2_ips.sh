#! /usr/bin/env bash

# ec2_ips.sh lists the public IP addresses of the _running_ EC2 instance in a
# particular region. If no region is specified, the default region---the one
# used by the aws command line tool when you don't specify a region---is used.
#
#   $ # List machines in default region.
#   $ ./aws_ips.sh
#   18.13.252.231
#   13.35.134.51
#   $ # List machines in us-west-1 region.
#   $ ./aws_ips.sh -r us-west-1
#   15.245.124.53
#   19.135.124.51

set -euo pipefail

usage() {
    echo "Usage: $1 [-r region] [-h]"
}

command_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

main() {
    while getopts ":hr:" opt; do
        case ${opt} in
            h )
                usage "$0"
                return 0
                ;;
            r )
                region="$OPTARG"
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

    if [[ "$#" -ne 0 ]]; then
        echo "Incorrect number of arguments provided."
        usage "$0"
        return 1
    fi

    if ! command_exists aws; then
        msg='The "aws" command does not exist. See the README '
        msg+='(github.com/mwhittaker/cluster_tools) for installation '
        msg+='instructions.'
        echo "$msg" | fold -w 80 -s
        return 1
    fi

    if ! command_exists jq; then
        msg='The "jq" command does not exist. Please install this command '
        msg+='(e.g. "sudo apt-get install jq") and try again.'
        echo "$msg" | fold -w 80 -s
        return 1
    fi

    aws ${region:+"--region=$region"} ec2 describe-instances \
        --filter="Name=instance-state-name,Values=running" \
    | jq \
        --monochrome-output \
        --raw-output \
        '.Reservations | .[] | .Instances | .[] | .PublicIpAddress'
}

main "$@"
