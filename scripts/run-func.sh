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

"$@"
