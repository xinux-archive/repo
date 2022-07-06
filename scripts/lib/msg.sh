#!/usr/bin/env bash
MsgCommon(){
    for i in $(seq "$(echo -e "${*}" | wc -l)"); do
        echo -e "${*}" | head -n "${i}" | tail -n 1
    done
}

MsgError(){
    MsgCommon "Error: ${*}" >&2
}

MsgInfo(){
    MsgCommon " Info: ${*}" >&1
}

MsgWarn(){
    MsgCommon " Warn: ${*}" >&2
}

MsgDebug(){
    [[ "${ShowDebugMsg}" = true ]] || return 0
    MsgCommon "Debug: ${*}" >&2
}


