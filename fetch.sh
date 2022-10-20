#!/usr/bin/env bash

# askpass () # <msg>
#   Helper command for --use-askpass of wget.
#   Return $HTTPUSER and $HTTPPASS
read WGET < <(type -p wget true)
if [ /proc/$PPID/exe -ef "$WGET" ]; then
  [[ "$1" =~ @ ]] && echo "$HTTPPASS" || echo "$HTTPUSER"
  exit
fi



source hhs.bash 0.2.0

declare -A UA=(
  [win64/fx85.0]="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:85.0) Gecko/20100101 Firefox/85.0"
  [win64/fx106.0]="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:106.0) Gecko/20100101 Firefox/106.0"
)
UA[0]="${UA[win64/fx106.0]}"

function readp () # <prompt>
#   read -p helper.
{
  local result
  read -p "$1" result && echo "$result"
}

function hash () # [-v <var>] <path>
#   Get SHA-512 hash of path.
{
  [ $# -eq 3 -a "$1" = "-v" -o $# -eq 1 ] || { error "Wrong arguments: $@"; return 1; }
  local ${2:+-n} result="$2"
  read -d" " result < <(echo -n "${@: -1}" | sha512sum)
  [ $# -eq 1 ] && echo $result || true
}

function init_fetch ()
{
  cachedir=/tmp/.cache/fetch
  [ -d "$cachedir" ] || mkdir -p "$cachedir"
  OPT_UA=( "-U" "$UA" )
  OPT_USE_ASKPASS="getpw.bash"
}

function optparse_fetch ()
{
  case "$1" in
  -S|--server-response)
    # Show server response
    nparams 0
    OPT_SERVER_RESPONSE=( -S )
    ;;
  --ask-password) #
    # Ask password
    nparams 0
    optset ASK_PASSWORD "$1"
    ;;
  -c|--cache-file)
    # Get cache file
    nparams 0
    optset CACHE_FILE "$1"
    ;;
  -f|--force) #
    # Force update
    nparams 0
    optset FORCE "$1"
    ;;
  --no-ua-pretend) #
    # No USER_AGENT	pretend
    nparams 0
    unset OPT_UA
    ;;
  -p|--progress)
    # Show progress
    nparams 0
    OPT_PROGRESS=( --show-progress )
    ;;
  -q|--quiet)
    # Quiet
    nparams 0
    OPT_QUIET=( -q )
    ;;
  --status) #
    # Show status
    nparams 0
    optset STATUS "$1"
    ;;
  --ua) # <user_agent>
    # Set USER_AGENT
    nparams 1
    OPT_UA=( -U "$2" )
    ;;
  -u|--user) # <user>
    # Set http user
    nparams 1
    OPT_USER=( --user "$2" )
    ;;
  --use-askpass) # <askpass>
    # Use askpass (default: getpw.bash)
    nparams 1
    optset USE_ASKPASS "$2"
    ;;
  *) return 1;;
  esac
}

function status () # <URL> <cache>
{
  local status; read status < <(stat -c "%y %10s" "$2")
  echo "${status%%.*} ${status##*+????} $1"
}

function fetch_one () # <URL>
#   fetch URL with cache.
{
  local hash; hash -v hash "$1"
  local cache="$cachedir/$hash"
  [ -n "$OPT_CACHE_FILE" ] && { echo "$cache"; return; }
  [ -n "$OPT_STATUS" ] && { status "$1" "$cache"; return; }

  if [[ ! -e "$cache" || -n "$OPT_FORCE" ]]; then
    local opts=( "${OPT_UA[@]}" "${OPT_USER[@]}" "${askpass[@]}" "${OPT_PROGRESS[@]}" "${OPT_QUIET[@]}" "${OPT_SERVER_RESPONSE[@]}" )
    local cmd=( wget "${opts[@]}" -O "$cache" "$1" )
    [ -n "$DEBUG" ] && echo "${cmd[@]@Q}";
    if "${cmd[@]}"; then
      printf "%s\t%s\n" "$hash" "$1" >>"$cachedir/list"
    else
      rm "$cache" >&/dev/null
      return 1
    fi
  fi
  cat "$cache"
}

function fetch () # [<URLs> ...]
#   fetch URLs with cache.
#   If set --ask-password option:
#   1. $HTTPUSER and $HTTPPASS is used for wget, if they are set.
#   2. Otherwise ask password from tty.
{
  local askpass=()
  if [ -n "$OPT_ASK_PASSWORD" ]; then
    local getpw; readarray -t getpw < <(type -p "$OPT_USE_ASKPASS" ${WGET_ASKPASS:+"$WGET_ASKPASS"} ${SSH_ASKPASS:+"$SSH_ASKPASS"} readp || echo readp)
    export HTTPUSER="${OPT_USER[1]:-$HTTPUSER}"; unset OPT_USER
    [ -z "$HTTPUSER" ] && read -p "Username: " HTTPUSER
    [ -z "$HTTPPASS" ] && export HTTPPASS="$("$getpw" "Password: ")"
    askpass=( --use-askpass "$0" )
  fi

  if (( 0 < $# )); then
    local i
    for i in "$@"; do
      fetch_one "$i"
    done
  else
    invoke_usage
  fi
}

invoke_command "$@"
