CheckPkg(){
    local p
    for p in "$@"; do
        pacman -Qq "$p" || return 1
    done
    return 0
}

# GetPacmanArch <ARCH>
GetPacmanArch(){
    local _Arch="${1}"
    pacman-conf --config="$MainDir/configs/pacman-$_Arch.conf" Architecture
}
