#!/usr/bin/env bash

declare -r CWD="$( cd -P "$([[ -d "${BASH_SOURCE[0]%/*}" ]] && echo "${BASH_SOURCE[0]%/*}" || pwd)" && pwd )"
declare -r SEARCH_PATH="${1:-.}"
declare -r SEARCH_DEPTH="${2:-30}"
declare -r SEARCH_PATTERNS=("*Spec.jsx" "*Spec.js")

declare -r ESCAPE_CHAR_MAC="\033"
declare -r ESCAPE_CHAR_LINUX="\e"
declare -r ESCAPE_CHAR="$([[ "$(uname)" == "Darwin" ]] && echo -n "$ESCAPE_CHAR_MAC" || echo -n "$ESCAPE_CHAR_LINUX")"
declare -r BOLD='0'
declare -r BACK='3'
declare -r ERROR_RED="${ESCAPE_CHAR}[0;41m"
declare -r RED="${ESCAPE_CHAR}[${BOLD};${BACK}1m"
declare -r GREEN="${ESCAPE_CHAR}[${BOLD};${BACK}2m"
declare -r YELLOW="${ESCAPE_CHAR}[${BOLD};${BACK}3m"
declare -r BLUE="${ESCAPE_CHAR}[${BOLD};${BACK}4m"
declare -r CLEAR="\\${ESCAPE_CHAR}c"
declare -r NC="${ESCAPE_CHAR}[${BOLD};0m"
declare -r GO_SCRIPT="specChecker.go"
declare -r OUTPUT_PIPE="${CWD}/output.pipe"
declare -r ERROR_PIPE="${CWD}/error.pipe"
declare -r VIOLATIONS_LOG="${CWD}/violations.log"
declare -i IS_NUM_CAP=0

declare fileList

error() {
  local template="$1" && shift 1
  printf "${ERROR_RED}${template//\%s/${NC}%s${ERROR_RED}}${NC}\n" $*
}

warn() {
  local template="$1" && shift 1
  printf "${YELLOW}${template//\%s/${NC}%s${YELLOW}}${NC}\n" $*
}

info() {
  local template="$1" && shift 1
  printf "${BLUE}${template//\%s/${NC}%s${BLUE}}${NC}\n" $*
}

success() {
  local template="$1" && shift 1
  printf "${GREEN}${template//\%s/${NC}%s${GREEN}}${NC}\n" $*
}

log() {
  printf "%s\n" "$1" >> "$VIOLATIONS_LOG"
}

depend() {
  command -v "$1" > /dev/null || { error "Command not found: $1"; exit 127; }
}

find() (
  local work_path='.' depth=1 pattern='*' a='' matches=() i j
  test -d "$1" && work_path="$1" && shift 1
  test -n "$1" && depth=$1 && shift 1
  test -n "$1" && pattern="$1"
  for ((i = 0; i < $depth; i++)); do
    matches=("$work_path"$a/$pattern)
    for j in "${matches[@]}"; do
      [[ -e "$j" ]] && echo "$j"
    done
    a+='/**'
  done
)

depend date
depend uname
depend go

echo -n > "$VIOLATIONS_LOG"

info "Searching %s files in %s" "$(IFS=, ; echo "${SEARCH_PATTERNS[*]}")" "$SEARCH_PATH"

for pattern in "${SEARCH_PATTERNS[@]}"; do
  fileList+="$(find "$SEARCH_PATH" "$SEARCH_DEPTH" $pattern)"
  fileList+=$'\n'
done

while read -r file; do
  if [[ -n "$file" && -f "$file" ]]; then
    go run "$GO_SCRIPT" "$file" 2>"$ERROR_PIPE" 1>"$OUTPUT_PIPE" 
    
    while :; do
      read -ru 5 output
      read -ru 6 err

      if [[ -z "$output" && -z "$err" ]]; then
        success "No violations found in file: %s" "$file"
        break
      elif [[ -n "$err" ]]; then
        error "$err"
      elif [[ -n "$output" ]]; then
        log "Violations found in file: $file"
        log "$output"
        warn "Violation found in file: %s" "$file"
        warn "$output"
      fi
    done  5<"$OUTPUT_PIPE" 6<"$ERROR_PIPE"
  fi
done <<< "$fileList"
