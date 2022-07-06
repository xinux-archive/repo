#!/usr/bin/env bash

# ParseCmdOpt LONG="<GNU getopt's long option>" SHORT="<GNU getopt's short option>" -- "${@}"
# This function does not support the option argument (Example: 'a::')
# It will return an array named OPTRET
ParseCmdOpt(){
  local _Arg _Chr _Cnt # Temporary variable for loop
  local _Long=() _LongWithArg=() _Short=() _ShortWithArg=() 
  local _OutArg=() _NoArg=() # Parsed array
  local _ParseFinished=false

  for _Arg in "${@}"; do
    local _TempArray=()
    case "${_Arg}" in
      "LONG="* )
        readarray -t _TempArray < <(tr -d "\"" <<< "${_Arg#LONG=}" | tr "," "\n")
        for _Chr in "${_TempArray[@]}"; do
          if [[ "${_Chr}" = *":" ]]; then
            _LongWithArg+=("${_Chr%":"}")
          else
            _Long+=("${_Chr}")
          fi
        done
        shift 1
      ;;
      "SHORT="*)
        readarray -t _TempArray < <(tr -d "\"" <<< "${_Arg#SHORT=}" | grep -o .)
        for (( _Cnt=0; _Cnt<= "${#_TempArray[@]}" - 1; _Cnt++ )); do
            if [[ "${_TempArray["$(( _Cnt + 1))"]-""}" = ":" ]]; then
              _ShortWithArg+=("${_TempArray["${_Cnt}"]}")
              _Cnt=$(( _Cnt + 1 ))
            else
              _Short+=("${_TempArray["${_Cnt}"]}")
            fi
        done
        shift 1
      ;;
      "--")
        shift 1
        break
      ;;
    esac
  done
  
  # Parse actually argument
  while (( "$#" > 0 )); do

    if [[ "${1}" = "--" ]]; then
      shift 1
      _NoArg+=("${@}")
      shift "$#"
      _ParseFinished=true
      break
    elif [[ "${1}" = "--"* ]]; then # Long option
      # Long option with argument
      if printf "%s\n" "${_LongWithArg[@]}" | grep -qx "${1#--}"; then
        # Check argument
        if [[ "${2}" = "-"* ]]; then
          MsgError "${1} No arguments are specified"
          return 1
        else
          _OutArg+=("${1}" "${2}")
          shift 2
        fi
      elif printf "%s\n" "${_Long[@]}" | grep -qx "${1#--}"; then
        _OutArg+=("${1}")
        shift 1
      else
        MsgError "${1} is an invalid option. Please check how to use it with -h."
        return 1
      fi
    elif [[ "${1}" = "-"* ]]; then
      local _Shift=0
      while read -r _Chr; do
        if printf "%s\n" "${_ShortWithArg[@]}" | grep -qx "${_Chr}"; then
          if [[ "${1}" = *"${_Chr}" ]] && [[ ! "${2}" = "-"* ]]; then
            _OutArg+=("-${_Chr}" "${2}")
            _Shift=2
          else
            MsgError "-${_Chr} の引数が指定されていません"
            return 2
          fi
        elif printf "%s\n" "${_Short[@]}" | grep -qx "${_Chr}"; then
          _OutArg+=("-${_Chr}")
          _Shift=1
        else
          MsgError "-${_Chr} is an invalid option. Please check how to use it with -h."
          return 1
        fi
      done < <(grep -o . <<< "${1#-}")
      shift "${_Shift}"
    else
      _NoArg+=("${1}")
      shift 1
    fi
  done

  OPTRET=("${_OutArg[@]}" -- "${_NoArg[@]}")  
}
