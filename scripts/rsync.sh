#!/usr/bin/env bash
set -Eeu

#-- Initilize --#
CurrentDir="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
LibDir="$CurrentDir/lib"
source "$LibDir/msg.sh"
source "$LibDir/shellfunc.sh"
source "$LibDir/parsecmdopt.sh"

#-- Configs --#
ShowDebugMsg=true
SecretKey=""
Server=""
Port="22"
LocalBackupDir=""
LocalRepoPath=""
RemoteRepoPath=""
ConfigFile=""
Backup=false

#-- Functions --#
HelpDoc(){
    echo "usage: sftp.sh [Option] [User@Server] [Remote Path] [Local Path]"
    echo "     : sftp.sh [Option] --config /path/to/config"
    echo
    echo " General options:"
    echo "    -b | --backup"
    echo "    -c | --config FILE       Specify config file"
    echo "    -p | --port PORT"
    echo "    -i | --key | --identity FILE"
    echo "                             SSH identity file path"
    echo "         --bkdir DIR         Local directory to backup"
    echo "    -h | --help              This help message"
}


RunSftpCmd(){
    MsgDebug "Run: $*"
    SftpCmd+=("$@" "\0")
}
PrintSftpCmd(){
    local s
    for s in "${SftpCmd[@]}";do 
        if [[ "$s" = "\0" ]]; then
            echo
        else
            echo -en "${s} "
        fi
    done | sed "s| $||g"
}

SftpCmd=()
SftpArgs=()
RsyncArgs=()
IgnoreRsyncArgs=()

#-- Parse Opts --#
ParseCmdOpt SHORT="bc:hi:p:" LONG="backup,config:,port:,key:,identity:,bkdir:,help" -- "${@}" || exit 1
eval set -- "${OPTRET[@]}"
unset OPTRET

while true; do
    case "${1}" in
        -b | --backup)
            Backup=true
            shift 1
            ;;
        -c | --config)
            ConfigFile="$2"
            shift 2
            ;;
        -h | --help)
            HelpDoc
            exit 0
            ;;
        -i | --identity | --key)
            SecretKey="$2"
            shift 2
            ;;
        -p | --port)
            Port="$2"
            shift 2
            ;;
        --bkdir)
            LocalBackupDir="$2"
            shift 2
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

#set -xv

if [[ -n "${ConfigFile-""}" ]]; then
    if [[ -e "$ConfigFile" ]]; then
        source "$ConfigFile"
    fi
else
    Server="${1-""}"
    RemoteRepoPath="${2-""}"
    LocalRepoPath="${3-""}"
    if (( "$#" < 3 )); then
        HelpDoc
        exit 1
    elif (( "$#" >= 3 )); then
        shift 3
    else
        shift "$#"
    fi
fi


#-- Set SFTP Commands --#
RunSftpCmd cd "$(dirname "$RemoteRepoPath")"
if [[ "$Backup" = true ]]; then
    BackupDate="$(date "+%Y%m%d-%H:%M:%S")"
    DirName="$(basename "${LocalRepoPath%/}").${BackupDate}.remote-old"
    RunSftpCmd get -r "${RemoteRepoPath}" "${LocalBackupDir}/${DirName}"
    RunSftpCmd mkdir "${RemoteRepoPath%/}.backup/${DirName}"
    RunSftpCmd put -r "${LocalBackupDir}/$DirName" "${RemoteRepoPath%/}.backup/"
fi
#while read -r Dir;do
#    RunSftpCmd rm "$RemoteRepoPath/$Dir/*"
#    RunSftpCmd rmdir "$RemoteRepoPath/$Dir"
#done < <(find "${LocalRepoPath}" -mindepth 1 -maxdepth 1 | sed "s|$LocalRepoPath||g" | tac)
#RunSftpCmd rmdir "$(basename "$_RemoteRepoPath")"
RunSftpCmd mkdir "$(basename "$RemoteRepoPath")"
#RunSftpCmd put -r "$LocalRepoPath" "$(basename "$_RemoteRepoPath")"
RunSftpCmd bye

#-- Setup SFTP argument --#
if [[ -n "$Port" ]]; then
    SftpArgs+=("-oPort=$Port")
fi
SftpArgs+=("${Server}:${RemoteRepoPath}")

#-- Run SFTP --#
PrintSftpCmd | sftp "${SftpArgs[@]}"

#-- Setup rsync argument--#
RsyncArgs+=(
    "--recursive"
    "--verbose"
    "--progress"
    "--links"
)
if [[ -n "${Port-""}" ]]; then
    RsyncArgs+=("--port=$Port")
fi
if [[ -n "${SecretKey-""}" ]]; then
    RsyncArgs+=("-e ssh -i \"$SecretKey\"")
fi
RsyncArgs=("${RsyncArgs[@]}" "${LocalRepoPath}/" "${Server}:${RemoteRepoPath}") 

for s in "${IgnoreRsyncArgs[@]}"; do
    readarray -t RsyncArgs < <(PrintArray "${RsyncArgs[@]}" | grep -vx -- "$s")
done

#-- Run rsync --#
MsgDebug "rsync ${RsyncArgs[*]}"
rsync "${RsyncArgs[@]}"
