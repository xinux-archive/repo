# CheckGpgKey <Key>
CheckGpgKey(){
    local _Key="$1"
    if gpg -u "$_Key" -s -n "/dev/null"; then
        return 0
    fi
    return 1
}

GetGpgSecretKeyList(){
    gpg --list-secret-keys | grep -E "^sec" -A 1 | grep "^ " | sed "s|^ *||g"
}
