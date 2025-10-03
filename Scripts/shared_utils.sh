#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

declare -r SRC_DIR="$(dirname "$(realpath "$0")")"
declare -r AUR_LIST=("yay" "paru")
declare -r SHELL_LIST=("zsh" "fish")

# Constants for colors
declare -r RED_COLOR=$'\033[0;31m'
declare -r GREEN_COLOR=$'\033[0;32m'
declare -r YELLOW_COLOR=$'\033[0;33m'
declare -r BLUE_COLOR=$'\033[0;34m'
declare -r DEFAULT_COLOR=$'\033[0m'

# Constants for exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

get_timestamp() {
    date '+%F %r'
}

log_info() {
  local -r message="${1:-}"
  printf "[$(get_timestamp)] $BLUE_COLOR[INFO]$DEFAULT_COLOR %s\n" "$message"
}

log_warning() {
  local -r message="${1:-}"
  printf "[$(get_timestamp)] $YELLOW_COLOR[WARNING]$DEFAULT_COLOR %s\n" "$message"
}

log_error() {
  local -r message="${1:-}"
  printf "[$(get_timestamp)] $RED_COLOR[ERROR]$DEFAULT_COLOR %s\n" "$message"
}

log_success() {
  local -r message="${1:-}"
  printf "[$(get_timestamp)] $GREEN_COLOR[SUCCESS]$DEFAULT_COLOR %s\n" "$message"
}

check_file_exists() {
  local -r file="${1:-}"

  if [[ ! -f "$file" ]]; then
    log_error "File '$file' does not exist!"
    exit $EXIT_FAILURE
  fi
}

is_package_available() {
  local -r package="$1"

  pacman -Si "$package" &>/dev/null
}

is_package_installed() {
  local -r package="$1"

  pacman -Qi "$package" &>/dev/null
}

get_installed_package() {
  local var_name="$1"
  local -r package_list=("${@:2}")

  for package in "${package_list[@]}"; do
    if is_package_installed "$package"; then
      printf -v "$var_name" "%s" "$package"
      export "$var_name"
      return $EXIT_SUCCESS
    fi
  done

  return $EXIT_FAILURE
}

get_user_prefs() {
  # Get the AUR helper
  if ! get_installed_package "aur_helper" "${AUR_LIST[@]}"; then
    printf "Select AUR helper:\n"
    printf " [1] yay\n"
    printf " [2] yay (bin)\n"
    printf " [3] paru\n"
    printf " [4] paru (bin)\n"
    read -p "Enter a number (default = paru): " aur_option
  
    case ${aur_option:-3} in
      1) aur_option="yay" ;;
      2) aur_option="yay-bin" ;;
      3) aur_option="paru" ;;
      4) aur_option="paru-bin" ;;
      *) aur_option="paru" ;;
    esac
  
    export aur_option
  fi
  
  # Get the user shell
  if ! get_installed_package "user_shell" "${SHELL_LIST[@]}"; then
    printf "Select user shell:\n"
    printf " [1] zsh\n"
    printf " [2] fish\n"
    read -p "Enter a number (default = zsh): " shell_option
  
    case ${shell_option:-1} in
      1) shell_option="zsh" ;;
      2) shell_option="fish" ;;
      *) shell_option="zsh" ;;
    esac
  
    export shell_option
  fi
}

parse_args() {
  install_flag=false
  restore_flag=false
  service_flag=false

  while getopts ":inrs" arg; do
    case $arg in
      i) install_flag=true ;;
      n) install_flag=true ; export use_default="--noconfirm" ;;
      r) restore_flag=true ;;
      s) service_flag=1 ;;
      *) print_usage ; exit $EXIT_FAILURE ;;
    esac
done

  if [[ $OPTIND -eq 1 ]]; then
    install_flag=true
    restore_flag=true
    service_flag=true
  fi
}

print_usage() {
  cat << EOF
A 'Hyprdots++' installation script.

Usage: $(basename "$0") [OPTIONS] [FILE]

Arguments:
  [FILE]  Additional packages to install ('custom_packages.lst').

Options:
  -i  Install without configuration files (interactive).
  -n  Install without configuration files (non-interactive).
  -r  Restore configuration files.
  -s  Activate system services.
  -h  Display this help message.

Defaults:
  If no options are provided, all actions are run interactively,
  equivalent to using '-i', '-r', and '-s' flags.

Examples:
  $(basename "$0")
  $(basename "$0") -h
  $(basename "$0") -i -r
  $(basename "$0") -n -r -s
EOF
}
