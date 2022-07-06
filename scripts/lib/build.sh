# BuildPkg <arch> <repo name> <pkgbuild1> <pkgbuild2> ...
BuildPkg(){
    local _Arch="$1" _RepoName="$2"
    local _Repo="$OutDir/$_RepoName"
    shift 2
    _ToBuildPkg=("$@")

    MsgDebug "Start BuildPkg for ${_RepoName}/${_Arch}"

    # Check arch
    CheckCorrectArch "$_Arch"

    # Load configs
    LoadShellFiles "$MainDir/repos/$_RepoName/repo-config.sh"
    LoadShellFiles "$MainDir/configs/config-$_Arch.sh"

    # Setup chroot
    MsgDebug "Setup Chroot environment for $_Arch"
    eval "SetupChroot_$_Arch"
    UpdateChrootPkgs "$_Arch"

    # Run makepkg
    while read -r _Pkg; do
        MsgDebug "Build $_Pkg"
        CheckAlreadyBuilt "$_Arch" "$_RepoName" "$_Pkg" || {
            MsgWarn "$(basename "$(dirname "$_Pkg")") has been built."
            continue
        }
        ! GetSkipPkgList "$_Arch" "$_RepoName" | grep -qx "$(basename "$(dirname "${_Pkg}")")" || {
            MsgWarn "$(basename "$(dirname "$_Pkg")") has set as SkipPkg_${_Arch}"
            MsgWarn "Skip the build it for $_Arch"
            continue
        }
        RunMakePkg "$_Arch" "$_Pkg"
        MovePkgToPool "$_Arch" "$_RepoName" "$_Pkg"
        #CreateRepoLockFile "$_Arch" "$_RepoName" "$_Pkg"
    done < <(PrintArray "${_ToBuildPkg[@]}")

    # Update repo
    UpdateRepoDb "$(basename "$_Repo")"
}

# BuildALlPkg <repo name>
BuildAllPkg(){
    local _RepoName="$1" _PkgList _ArchList
    readarray -t _PkgList < <(GetPkgbuildList "$_RepoName")
    BuildAllArch "$_RepoName" "${_PkgList[@]}"
}

# BiildAllArch <repo name> <pkgbuild1> <pkgbuild2> ...
BuildAllArch(){
    local _RepoName="$1"
    shift 1
    local _PkgList=("$@") _ArchList
    readarray -t _ArchList < <(GetRepoArchList "$_RepoName")

    for _Arch in "${_ArchList[@]}"; do
        BuildPkg "$_Arch" "$_RepoName" "${_PkgList[@]}"
    done
}

BuildAllPkgInAllRepo(){
    local _repo _Arch
    while read -r _repo; do
        MsgDebug "Found repository: $_repo"
        BuildAllPkg "${_repo}"
    done < <(GetRepoList)
}

# setarch <arch> [args]
setarch(){
    local _Bin _Arch="$1"
    _Bin="$(which setarch)"
    shift 1
    case "$_Arch" in
        "pen4")
            _Arch="athlon"
            ;;
    esac
    "$_Bin" "$_Arch" "$@"
}

makechrootpkg(){
    "$CurrentDir/makechrootpkg" -s "$@"
}
