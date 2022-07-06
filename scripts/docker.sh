#!/usr/bin/env bash

set -Eeuxv

#-- Initialize --#
CurrentDir="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
ScriptName="$0"
RawArgument=("$@")
LibDir="$CurrentDir/lib"
MainDir="$CurrentDir/../"
ReposDir="$CurrentDir/../repos"
source "${LibDir}/loader.sh"


#-- Functions --#
HelpDoc(){
    echo "usage: docker.sh [user] [Command] [Option]"
    echo
    echo " General options:"
    echo "    -g | --group GID"
    echo "    -u | --user UID"
    echo "    -h | --help              This help message"
}

GROUP_ID="${GROUP_ID-""}"
USER_ID="${USER_ID-""}"

#-- Show debug info --#
ShowVariable USER_ID
ShowVariable GROUP_ID

ShowVariable XINUX_MAIN_DIR
ShowVariable XINUX_WORK_DIR
ShowVariable XINUX_OUT_DIR
ShowVariable XINUX_SIGN_KEY
ShowVariable XINUX_GPG_DIR

#-- Parse Opts --#
ParseCmdOpt SHORT="g:u:h" LONG="group:,user:,help" -- "${@}" || exit 1
eval set -- "${OPTRET[@]}"
unset OPTRET

while true; do
    case "${1}" in
        -g | --group)
            GROUP_ID="$2"
            shift 2
            ;;
        -u | --user)
            USER_ID="$2"
            shift 2
            ;;
        -h | --help)
            HelpDoc
            exit 0
            ;;
        --)
            shift 1
            break
            ;;
        *)
            MsgError "Argument exception error '${1}'"
            MsgError "Please report this error to the developer." 1
            ;;
    esac
done
USER="${1-""}"
[[ -n "$USER" ]] || exit 1
shift 1


#-- Run --#
set -xv
HomeDir="$(eval echo ~"$USER")"
sudo usermod -u "$USER_ID" -o "$USER"
sudo groupmod -g "$GROUP_ID" "$USER"

ShowVariable XINUX_MAIN_DIR
ShowVariable XINUX_WORK_DIR
ShowVariable XINUX_OUT_DIR
ShowVariable XINUX_SIGN_KEY
ShowVariable XINUX_GPG_DIR

FixPermission(){
    sudo chmod 755 -R "$1"
    sudo chown -R "$USER:$USER" "$1"
}

FixPermission "$XINUX_MAIN_DIR"
FixPermission "$XINUX_OUT_DIR"
if [[ ! -e "$XINUX_WORK_DIR/Chroot" ]]; then
    FixPermission "$XINUX_WORK_DIR"
fi

sudo -u "$USER" --preserve-env=XINUX_MAIN_DIR,XINUX_WORK_DIR,XINUX_OUT_DIR,XINUX_SIGN_KEY,XINUX_GPG_DIR "$@"
