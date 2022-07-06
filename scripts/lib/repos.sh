GetRepoList(){
    GetRepoFullPath| GetBaseName
}

GetRepoFullPath(){
    find "${ReposDir}" -mindepth 1 -maxdepth 1 -type d
}

# GetPkgbuildList <repo name>
GetPkgbuildList(){
    local _Repo="$ReposDir/$1"

    find "$_Repo" -mindepth 1 -name "PKGBUILD" -type f
}

# RunEachArch <repo name> <cmmands>
# {} will be replaced to architecture name
RunEachArch(){
    local _Arch _Cmd _Repo="$1"
    local _CmdArray=()
    shift 1 || return 0

    while read -r _Arch; do
        _CmdArray=()
        for _Cmd in "$@"; do
            # shellcheck disable=SC2001
            _CmdArray+=("$(sed "s|{}|$_Arch|g" <<< "${_Cmd}")")
        done
        "${_CmdArray[@]}"
    done < <(GetRepoArchList "$_Repo")
}

# UpdateRepoDb <repo name>
UpdateRepoDb(){
    local _Repo="$1"
    local _Pool="${OutDir}/$_Repo/pool/packages"
    local _RepoDir="${OutDir}/$_Repo/os/"
    local _File _Arch _Path

    while read -r _Path; do

        _File="$(basename "$_Path")"
        _Arch=$(GetPkgArch "$_File")
        MsgDebug "Meta Update: $_Path"

        # Setup files
        rm -rf "${_RepoDir:?}/${_Arch:?}/${_File:?}" 

        # Function to add pakage to db
        local _Add_Pkg
        _Add_Pkg(){
            local _Arch="$1" _Symlink
            #local _PArch
            
            _Symlink="$_RepoDir/$_Arch/${_File}"
            MsgDebug "Symlink will be created to $_Symlink"

            ! GetSkipPkgList "$_Arch" "$_Repo" | grep -qx "$(GetPkgName "$_File")" || {
                MsgWarn "Skip to add $(GetPkgName "$_File") to $_Arch"
                return 0
            }

            MakeDir "$(dirname "${_Symlink}")"

            if [[ -n "$GPGKey" ]]; then
                rm -rf "${_Path}.sig"
                gpg --output "${_Path}.sig" -u "$GPGKey" --detach-sig "${_Path}"
            fi

            #if [[ "$NoSymLink" = true ]]; then
            #    : #Todo
            #else
                MakeSymLink "../../pool/packages/$_File" "$_Symlink"

                if [[ -e "$_Path.sig" ]]; then
                    MakeSymLink "../../pool/packages/$_File.sig" "$_Symlink.sig"
                fi
            #fi

            #if [[ -n "$GPGKey" ]]; then
            #    repo-add --sign --key "$GPGKey" "$_RepoDir/${_Arch}/$_Repo.db.tar.gz" "$_Symlink"
            #else
                repo-add "$_RepoDir/${_Arch}/$_Repo.db.tar.gz" "$_Symlink"
            #fi
        }

        MsgDebug "Add $_File to database"
        case "$_Arch" in
            "any")
                RunEachArch "$_Repo" eval _Add_Pkg '"$(GetPacmanArch "{}")"'
                ;;
            *)
                _Add_Pkg "$_Arch"
                ;;
        esac

    done < <(find "$_Pool" -mindepth 1 -maxdepth 1 -name "*.pkg.tar.*" -type f | grep -v ".sig$")

    RunEachArch "$_Repo" eval MakeSymLink './os/$(GetPacmanArch {})' '${_RepoDir}/../$(GetPacmanArch {})'

    if [[ "${NoSymLink}" = true ]]; then
        find "${OutDir}/$_Repo" -type l | ForArray ReplaceLink "{}"
    fi
}

# CheckCorrectArch <arch>
CheckCorrectArch(){
    local _Err=0 _Arch="$1"

    CheckFunctionDefined "SetupChroot_$_Arch" || {
        MsgError "Setup chroot for $_Arch is not implemented."
        (( _Err+=1 ))
    }

    test -f "$MainDir/configs/pacman-$_Arch.conf" || {
        MsgError "pacman.conf for $_Arch does not exist"
        (( _Err+=1 ))
    }

    test -f "$MainDir/configs/config-$_Arch.sh" || {
        MsgWarn "Global config for $_Arch does not exist"
    }

    (( _Err == 0 )) || {
        MsgError "$_Err errors about $_Arch are found."
        return 1
    }
}


# GetRepoArchList <repo name>
GetRepoArchList(){ {
    local _RepoName="$1"
    local _Repo="$ReposDir/$_RepoName"
    if (( "${#OverRideRepoArch[@]}" > 0)); then
        PrintArray "${OverRideRepoArch[@]}"
    else
        LoadShellFiles "$_Repo/repo-config.sh"
        PrintArray "${RepoArch[@]}"
    fi
} }

# GetSkipPkgList <arch> <repo>
GetSkipPkgList(){ {
    local _Arch="$1" _RepoName="$2"
    local _Repo="$ReposDir/$_RepoName"
    LoadShellFiles "$_Repo/repo-config.sh"
    eval "PrintArray \"\${SkipPkg_${_Arch}[@]}\""
} }


# CreateRepoLockFile <arch> <repo> <pkgbuild>
#CreateRepoLockFile(){
#    local _Arch="$1" _RepoName="$2" _PkgBuild="$3"
#    local _LockFileDir="$WorkDir/LockFile/"
#    local _RepoFile="$_LockFileDir/$_RepoName"

#    MakeDir "$_LockFileDir"
#    [[ -e "$_RepoFile" ]] || { echo > "$_RepoFile"; }
#    readarray -t _FileList < <(
#        cd "$(dirname "$_PkgBuild")" || return 0
#        GetPkgListFromPKGBUILD "$_Arch" "./PKGBUILD" | GetBaseName)

#    local _Pkg
#    for _Pkg in "${_FileList[@]}"; do
#        echo "$_Pkg" >> "$_RepoFile"
#    done
#}


# CheckAlreadyBuilt <arch> <repo> <pkgbuild>
# return 1 => already built
# return 0 -> not built yet
#CheckAlreadyBuilt(){
#    local _Arch="$1" _RepoName="$2" _PkgBuild="$3"
#    local _LockFileDir="$WorkDir/LockFile/"
#    local _RepoFile="$_LockFileDir/$_RepoName"
#
#    [[ -e "$_RepoFile" ]] || return 0
#    readarray -t _FileList < <(
#        cd "$(dirname "$_PkgBuild")" || return 0
#        GetPkgListFromPKGBUILD "$_Arch" "${_PkgBuild}" | GetBaseName)
#
#    local _Pkg
#    for _Pkg in "${_FileList[@]}"; do
#        ! grep -qx "$_Pkg" "$_RepoFile" || return 1
#    done
#    return 0
#}

# CheckAlreadyBuilt <arch> <repo> <pkgbuild>
# return 1 => already built
# return 0 -> not built yet
CheckAlreadyBuilt(){
    local _Arch="$1" _RepoName="$2" _PkgBuild="$3"
    local _Pool="${OutDir}/$_RepoName/pool/packages"

    MsgDebug "Getting package file list from PKGBUILD"
    local _FileList=()
    readarray -t _FileList < <(GetPkgListFromPKGBUILD "$_Arch" "$_PkgBuild" | GetBaseName)
    
    for _File in "${_FileList[@]}"; do
        #MsgDebug "Pool=$_Pool"
        #MsgDebug "File=$_File"
        if [[ -e "$_Pool/$_File" ]]; then
            MsgDebug "Found $_Pool/$_File"
        else
            MsgDebug "Not found $_Pool/$_File"
            return 0
        fi
    done
    return 1
}

