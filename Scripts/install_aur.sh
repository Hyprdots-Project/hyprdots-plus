#!/usr/bin/env bash
#|--------/ /+----------------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_aur.sh                             |-------/ /-|#
#|------/ /--| Description: Install the AUR helper (yay or paru). |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com)         |-----/ /---|#
#|----/ /----|----------------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.1                                       |---/ /-----|#
#|--/ /------| Created: 2025-09-28                                |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-01                           |-/ /-------|#
#|/ /--------+----------------------------------------------------+/ /--------|#

: << 'DOC'
This script installs the specified AUR helper (defaults to paru).
It verifies that git is installed, clones the AUR helper repository,
and builds it locally using makepkg. The installation is skipped
if the AUR helper is already installed.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#----------------------#
# check git dependency #
#----------------------#
if ! is_package_installed "git"; then
  log_error "Dependency 'git' is not installed!"
  exit $EXIT_FAILURE
fi

#----------------#
# get AUR helper #
#----------------#
if ! get_installed_package "aur_helper" "${AUR_LIST[@]}"; then
  aur_helper="${1:-paru}"
else
  log_warning "Package '$aur_helper' is already installed, skipping..."
  exit $EXIT_SUCCESS
fi

#------------------#
# clone AUR helper #
#------------------#
readonly AUR_DIR="$HOME/.local/src/$aur_helper"
if [[ ! -d "$AUR_DIR" ]]; then
  # Ensure the parent directory exists
  mkdir -p "$(dirname "$AUR_DIR")"

  # Clone the AUR helper
  log_info "Cloning '$aur_helper' to '$AUR_DIR'..."
  if git clone "https://aur.archlinux.org/$aur_helper.git" "$AUR_DIR"; then
    printf "[Desktop Entry]\nIcon=default-folder-git\n" > "$AUR_DIR/.directory"
    log_success "Cloned '$aur_helper' to '$AUR_DIR'."
  else
    log_error "Failed to clone '$aur_helper' to '$AUR_DIR'!"
    [[ -d "$AUR_DIR" ]] && rm -rf "$AUR_DIR"
    exit $EXIT_FAILURE
  fi
else
  log_warning "Directory '$AUR_DIR' already exists, skipping clone..."
fi

#--------------------#
# install AUR helper #
#--------------------#
log_info "Installing '$aur_helper'..."
if cd "$AUR_DIR" && makepkg -si "$use_default"; then
  log_success "Installed '$aur_helper'."
else
  log_error "Failed to install '$aur_helper'!"
  exit $EXIT_FAILURE
fi

# End of install_aur.sh
