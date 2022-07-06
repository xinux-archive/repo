#!/usr/bin/env bash

set -Eeu

#-- Initialize --#
CurrentDir="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
ScriptName="$0"
RawArgument=("$@")
LibDir="$CurrentDir/lib"
MainDir="$CurrentDir/../"
ReposDir="$CurrentDir/../repos"
source "${LibDir}/loader.sh"

#-- Config --#
BuildRepo=()
BuildPkg=()
OverRideRepoArch=()
NoSymLink=false


#-- Debug Message --#
ShowVariable XINUX_WORK_DIR
ShowVariable XINUX_OUT_DIR
ShowVariable XINUX_SIGN_KEY
MainDir="${XINUX_MAIN_DIR-"${MainDir}"}"
OutDir="${XINUX_OUT_DIR-"${MainDir}/out"}"
WorkDir="${XINUX_WORK_DIR-"${MainDir}/work"}"
GPGDir="${XINUX_GPG_DIR-"${HOME}/.gnupg/"}"
GPGKey="${XINUX_SIGN_KEY-""}"
ChrootUser="hayao"

#-- Function --#
HelpDoc(){
    echo "usage: main.sh [option]"
    echo
    echo " General options:"
    echo "    -a | --arch Arch1,Arch2 ..."
    echo "    -g | --gpg KEY"
    echo "    -r | --repo REPO"
    echo "    -p | --pkg PkgBase1,PkgBase2 ..."
    echo "    -w | --work WORK_DIR"
    echo "    -o | --out OUT_DIR"
    echo "    -h | --help              This help message"
    #echo "         --rmlock            Remove all lockfile"
    echo "         --bash-debug        Show bash debug message"
    echo "         --gpgdir DIR        Specify GnuPG directory"
    echo "         --user USER         Specify username to chroot"
    echo "         --nolink            Do not create link and copy files"
}

PrepareBuild(){
    if ! pacman -Qq xinux-keyring 1> /dev/null 2>&1; then
        sudo pacman-key --init
        curl -Lo - "http://repo.dyama.net/fascode.pub" | sudo pacman-key -a -
        sudo pacman-key --lsign-key development@fascode.net
        sudo pacman --config "$MainDir/configs/pacman-x86_64.conf" -Sy --noconfirm xinux-stable/xinux-keyring
        sudo pacman-key --populate xinux
    fi

    # Setup user
    UserCheck "$ChrootUser" || useradd -m -g root -s /bin/bash "$ChrootUser"
    sudo chmod 775 -R "$ReposDir"

    # Run this script as ChrootUser
    if (( UID == 0 )); then
        sudo -E -u "$ChrootUser" "$ScriptName" "${RawArgument[@]}"
        exit "$?"
    fi

    # Create directory
    MakeDir "$WorkDir/Chroot" #"$WorkDir/LockFile"

    # RemoveLockFile
    #if [[ "${RemoveLockFile}" = true ]]; then
    #    rm -rf "$WorkDir/LockFile"
    #fi
}

CheckEnvironment(){
    # Package
    local _DependCmds=("pacman" "mkarchroot" "makepkg" "pacman-key")
    PrintArray "${_DependCmds[@]}" | ForArray CheckCommand "{}" || {
        MsgError "Please install it and try again"
        exit 1
    }
}

Main(){
    (( "${#BuildRepo[@]}" < 1 )) && {
        BuildAllPkgInAllRepo
        return 0
    }
    
    (( "${#BuildPkg[@]}" < 1 )) && {
        local _Repo
        for _Repo in "${BuildRepo[@]}"; do
            BuildAllPkg "$_Repo"
        done
        return 0
    }

    (( ${#BuildRepo[@]} > 1 )) && {
        MsgError "Error"
        return 1
    }

    local _Repo="${BuildRepo[*]}"
    readarray -t PkgBuildList < <(
        for _Pkg in "${BuildPkg[@]}"; do
            _PkgBuild="${ReposDir}/${_Repo}/${_Pkg}/PKGBUILD"
            [[ ! -e "${_PkgBuild}" ]] || echo "$_PkgBuild"
        done
    )
    BuildAllArch "$_Repo" "${BuildPkg[@]}"
}

#-- Parse command-line options --#
# Parse options
ParseCmdOpt SHORT="a:g:ho:p:r:w:" LONG="arch:gpg:help,out:,pkg:,repo:,work:,rmlock,gpgdir:,user:,bash-debug,nolink" -- "${@}" || exit 1
eval set -- "${OPTRET[@]}"
unset OPTRET

while true; do
    case "${1}" in
        -a | --arch)
            IFS="," read -r -a OverRideRepoArch <<< "${2}"
            shift 2
            ;;
        -g | --gpg)
            GPGKey="$2"
            shift 2
            ;;
        -o | --out)
            OutDir="$2"
            shift 2
            ;;
        -p | --pkg)
            readarray -t BuildPkg < <(PrintOneLineCSV "$2")
            shift 2
            ;;
        -r | --repo)
            readarray -t BuildRepo < <(PrintOneLineCSV "$2")
            shift 2
            ;;
        -w | --work)
            WorkDir="$2"
            shift 2
            ;;
        -h | --help)
            HelpDoc
            exit 0
            ;;
        --rmlock)
            #RemoveLockFile=true
            shift 1
            ;;
        --bash-debug)
            set -xv
            shift 1
            ;;
        --gpgdir)
            GPGDir="$2"
            shift 2
            ;;
        --user)
            ChrootUser="$2"
            shift 2
            ;;
        --nolink)
            NoSymLink=true
            shift 1
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

#-- Run --#
#set -xv
export GNUPGHOME="$GPGDir"
CheckEnvironment
PrepareBuild
Main
