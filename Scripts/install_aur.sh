#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_aur.sh                     |-------/ /-|#
#|------/ /--| Description: Install the AUR helper.       |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-18                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-18                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script installs the specified AUR helper (defaults to paru).
It verifies that git is installed, clones the AUR helper repository,
and builds it locally using makepkg. Installation is skipped if the
AUR helper is already installed.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#----------------#
# get AUR helper #
#----------------#
if ! get_installed_package "aur_helper" "${aur_list[@]}"; then
  aur_helper="${1:-paru}"
else
  print_warning "The '$aur_helper' AUR helper is already installed, skipping..."
  exit $EXIT_SUCCESS
fi

#----------------------#
# check git dependency #
#----------------------#
if ! is_pkg_installed "git"; then
  print_error "The required 'git' dependency is not installed!"
  exit $EXIT_FAILURE
fi

#----------------#
# define AUR dir #
#----------------#
declare -r AUR_DIR="$HOME/.local/share/$aur_helper"

#------------------#
# clone AUR helper #
#------------------#
if [[ ! -d "$AUR_DIR" ]]; then
  print_info "Cloning the '$aur_helper' AUR helper to '$AUR_DIR'..."
  if git clone "https://aur.archlinux.org/$aur_helper.git" "$AUR_DIR"; then
    echo -e "[Desktop Entry]\nIcon=default-folder-git" > "$AUR_DIR/.directory"
    print_success "Cloned the '$aur_helper' AUR helper to '$AUR_DIR'."
  else
    print_error "Failed to clone the '$aur_helper' AUR helper!"
    exit $EXIT_FAILURE
  fi
else
  print_warning "The '$AUR_DIR' directory already exists, skipping clone..."
fi

#--------------------#
# install AUR helper #
#--------------------#
print_info "Installing the '$aur_helper' AUR helper..."
if cd "$AUR_DIR" && makepkg -si; then
  print_success "Installed the '$aur_helper' AUR helper."
else
  print_error "Failed to install the '$aur_helper' AUR helper!"
  exit $EXIT_FAILURE
fi

# End of install_aur.sh
