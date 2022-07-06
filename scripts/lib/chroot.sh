SetupChroot_x86_64(){
    local CHROOT="$WorkDir/Chroot/x86_64/"
    MakeDir "$CHROOT"

    [[ -e "$CHROOT/root/etc/pacman.conf" ]] && return 0

    # Create chroot
    mkarchroot \
        -C "$MainDir/configs/pacman-x86_64.conf" \
        -M "$MainDir/configs/makepkg-${_Arch}.conf" \
        "$CHROOT/root" "${ChrootPkg[@]}"

    # Update package
    arch-nspawn "$CHROOT/root" pacman -Syyu
}

SetupChroot_i686(){
    _SetupChroot_Arch32 i686
}

SetupChroot_pen4(){
    _SetupChroot_Arch32 pen4
}

# _SetupChroot_Arch32 <i686/pen4> 
_SetupChroot_Arch32(){
    local _Arch="$1"
    #case "$_Arch" in
    #    "pen4")
    #        _Arch="pentium4"
    #        ;;
    #esac

    local CHROOT="$WorkDir/Chroot/${_Arch}/"
    MakeDir "$CHROOT" "$WorkDir/Keyring"

    # Install archlinux32-keyring
    if ! pacman -Qq archlinux32-keyring && [[ "$(uname -m)" = "x86_64" ]]; then
        sudo pacman --config "$MainDir/configs/pacman-x86_64.conf" -Sy --noconfirm archlinux32-keyring
        sudo pacman-key --populate archlinux32
    fi
        

    [[ -e "$CHROOT/root/etc/pacman.conf" ]] && return 0

    # Create chroot
    mkarchroot \
        -C "$MainDir/configs/pacman-${_Arch}.conf" \
        -M "$MainDir/configs/makepkg-${_Arch}.conf" \
        "$CHROOT/root" "${ChrootPkg[@]}"

    # Update package
    #arch-nspawn "$CHROOT/root" pacman -Syyu
}

# Update chroot environment
# UpdateChrootEnv <ARCH>
UpdateChrootPkgs(){
    local _Arch="$1"
    local CHROOT="$WorkDir/Chroot/$_Arch/"

    MsgDebug "Update packages in chroot environment"
    setarch "$_Arch" arch-nspawn -s "$CHROOT/root" pacman -Syyu
}

# RunMakePkg <ARCH> <PKGBUILD PATH> <MAKEPKG Args ...>
RunMakePkg(){
    local MakeChrootPkg_Args=(-c -r "$WorkDir/Chroot/$1" -U "$ChrootUser")
    local Makepkg_Args=(--skippgpcheck --nocheck --noconfirm --ignorearch)
    local Pkgbuild="${2}"

    shift 2 || return 1
    Makepkg_Args+=("$@")

    MsgDebug "Run makepkg for $Pkgbuild"

    # Move to dir
    cd "$(dirname "$Pkgbuild")" || {
        MsgError "Failed to move the PKGBUILD's directory."
        return 1
    }

    # Run makechrootpkg
    RunCmd makechrootpkg "${MakeChrootPkg_Args[@]}" -- "${Makepkg_Args[@]}"
}

# MovePkgToPool <ARCH> <REPO NAME> <PKGBUILD Path>
MovePkgToPool(){
    local _Arch="$1" _Repo="$2" _Pkgbuild="$3" _PkgFile
    local _Pool="${OutDir}/$_Repo/pool/packages"

    # Move to dir
    cd "$(dirname "$_Pkgbuild")" || {
        MsgError "Failed to move the PKGBUILD's directory."
        return 1
    }

    # Make dir
    MakeDir "$_Pool"

    # Move
    while read -r _PkgFile; do
        for __File in "$_PkgFile" "$_PkgFile.sig"; do
            [[ -e "$__File" ]] && {
                MsgDebug "Move $__File to $_Pool"
                cp "$__File" "$_Pool"
                continue
            }
            MsgError "$__File does not exist"
        done
    done < <(GetPkgListFromPKGBUILD "$_Arch" "./PKGBUILD")
    return 0
}
