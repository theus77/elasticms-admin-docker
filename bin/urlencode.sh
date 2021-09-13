#!/bin/bash

url_encode() {
  # URL encode string and optionally store in shell variable
  #
  # usage: urlencode <string> [var]

  local LC_ALL=C
  local encoded=""
  local i c

  for (( i=0 ; i<${#1} ; i++ )); do
     c=${1:$i:1}
     case "$c" in
        [a-zA-Z0-9/_.~-] ) encoded="${encoded}$c" ;;
        * ) printf -v encoded "%s%%%02x" "$encoded" "'${c}" ;;
     esac
  done
  [ $# -gt 1 ] &&
     printf -v "$2" "%s" "${encoded}" ||
     printf "%s\n" "${encoded}"
}
#UTF-8