#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_packages.sh                |-------/ /-|#
#|------/ /--| Description: Install packages.             |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-28                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-28                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script reads a list of packages from a file (defaults to 'install_packages.lst'),
iterates through them, and installs each package.
It ignores comments and empty lines in the package list file,
and skips packages where its dependency is not satisfied.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf "\033[0;31m[ERROR]\033[0m Failed to source '%s'!\n" \
    "shared_utils.sh" >&2
  exit 1
fi

#--------------------#
# install AUR helper #
#--------------------#
"$SCR_DIR/install_aur.sh" "$get_aur"
get_installed_package "aur_helper" "${AUR_LIST[@]}"

#-------------------------#
# check package list file #
#-------------------------#
declare -r PACKAGE_LIST="${1:-"$SRC_DIR/install_packages.lst"}"
check_file_exists "$PACKAGE_LIST"

#-----------------------#
# prepare package lists #
#-----------------------#
declare -a arch_packages=()
declare -a aur_packages=()

#-------------------------#
# get packages to install #
#-------------------------#
while IFS='|' read -r package deps; do
  # Skip empty lines
  [[ -z "$package" ]] && continue

  # Check the dependencies
  if [[ -n "$deps" ]]; then
    # Trim trailing whitespace
    deps="${deps%"${deps##*[![:space:]]}"}"

    # Iterate through the dependencies
    while read -r dep; do
      # Check if the dependency listed for installation
      is_listed=$(cut -d '#' -f 1 "$PACKAGE_LIST" | awk -F '|' -v dep="$dep" '{ if ($1 == dep) { print true; exit } }')

      if ${is_installed:-false}; then
        # Check if the dependency is installed
        if ! is_package_installed "$package_dep"; then
          log_warning "Package '$package' is missing '$dependency' dependency, skipping..."
          continue 2
        fi
      fi
    done < <(echo "$deps" | xargs -n 1)
  fi

  # Add the packages to install
  if is_package_installed "$package"; then
    log_warning "Package '$package' is already installed, skipping..." 
  elif is_package_available "$package"; then
    log_info "Adding '$package' from official arch repo..."
    arch_packages+=("$package")
  elif is_aur_available "$package"; then
    log_info "Adding '$package' from arch user repo..."
    aur_packages+=("$package")
  else
    log_error "Package '$package' is not known!"
    exit $EXIT_FAILURE
  fi
done < <(
  # Remove comments and trim leading/trailing whitespace
  cut -d "#" -f 1 "$PACKAGE_LIST" \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

#---------------------------#
# install official packages #
#---------------------------#
if [[ ${#arch_packages[@]} -gt 0 ]]; then
  log_info "Installing official packages..."
  if sudo pacman "$use_default" -S "${arch_packages[@]}"; then
    log_success "Installed official packages."
  else
    log_error "Failed to install official packages!"
    exit $EXIT_FAILURE
  fi
else
  log_warning "There are no official packages to install, skipping..."
fi

#----------------------#
# install AUR packages #
#----------------------#
if [[ ${#aur_packages[@]} -gt 0 ]]; then
  log_info "Installing 'AUR' packages..."
  if "$aur_helper" "$use_default" -S "${aur_packages[@]}"; then
    log_success "Installed 'AUR' packages."
  else
    log_error "Failed to install 'AUR' packages!"
    exit $EXIT_FAILURE
  fi
else
  log_warning "There are no 'AUR' packages to install, skipping..."
fi

# End of install_packages.sh
