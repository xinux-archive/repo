# GetPkgListFromPKGBUILD <ARCH> <PKGBUILD>
GetPkgListFromPKGBUILD(){
    local _Arch="$1" _PkgBuild="$2"
    cd "$(dirname "$_PkgBuild")" || return 1
    RunCmd setarch "$_Arch" sudo -u "$ChrootUser" makepkg --config "$MainDir/configs/makepkg-${_Arch}.conf" --ignorearch --packagelist -p "$(basename "${_PkgBuild}")"
}

# ParsePkgFileName <Pacman package file name>
ParsePkgFileName(){
    local _Pkg="$1"
    local _PkgName _PkgVer _PkgRel _Arch _FileExt  
    local _PkgWithOutExt

    # File name
    if grep "/" <<< "$_Pkg"; then
        _Pkg="$(basename "$_Pkg")"
    fi

    # Parse
    _FileExt="$(GetLastSplitString "-" "$_Pkg" | cut -d "." -f 2-)" #pkg.tar.zst
    _PkgWithOutExt="${_Pkg%%".${_FileExt}"}" 
    _Arch=$(GetLastSplitString "-" "${_PkgWithOutExt}")
    _PkgRel=$(GetLastSplitString "-" "${_PkgWithOutExt%%"-${_Arch}"}")
    _PkgVer=$(GetLastSplitString "-" "${_PkgWithOutExt%%"-${_PkgRel}-${_Arch}"}")
    _PkgName="${_PkgWithOutExt%%"-${_PkgVer}-${_PkgRel}-${_Arch}"}"

    _ParsedPkg=("${_PkgName}" "-" "$_PkgVer" "-" "$_PkgRel" "-" "$_Arch" ".$_FileExt")

    if [[ ! "$(PrintArray "${_ParsedPkg[@]}" | tr -d "\n")" = "${_Pkg}" ]]; then
        MsgError "Failed to parse $_Pkg"
        MsgError "Please report it to developer"
        return 1
    fi
    PrintArray "${_ParsedPkg[@]}"
}

#Get* <Pacman package file name>
GetPkgName(){ ParsePkgFileName "$1" | GetLine 1 ;}
GetPkgVer (){ ParsePkgFileName "$1" | GetLine 3 ;}
GetPkgRel (){ ParsePkgFileName "$1" | GetLine 5 ;}
GetPkgArch(){ ParsePkgFileName "$1" | GetLine 7 ;}
GetPkgExt (){ ParsePkgFileName "$1" | GetLine 8 ;}
