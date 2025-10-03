#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_packages.sh                |-------/ /-|#
#|------/ /--| Description: Install the packages.         |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.1                               |---/ /-----|#
#|--/ /------| Created: 2025-10-01                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-03                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script reads a list of packages from the specified file
(defaults to 'install_packages.lst' if no argument is provided),
iterates through them, and installs each package.
It ignores comments and empty lines in the package list file,
and skips packages whose dependencies are not satisfied.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#--------------------#
# install AUR helper #
#--------------------#
"$SCR_DIR/install_aur.sh" "$aur_option"
get_installed_package "aur_helper" "${AUR_LIST[@]}"

#-------------------------#
# check package list file #
#-------------------------#
readonly PACKAGE_LIST="${1:-"$SRC_DIR/install_packages.lst"}"
check_file_exists "$PACKAGE_LIST"

#------------------------#
# declare package arrays #
#------------------------#
declare -a arch_packages=()
declare -a aur_packages=()

#-------------------------#
# get packages to install #
#-------------------------#
while IFS='|' read -r package deps; do
  # Skip empty lines
  [[ -z "$package" ]] && continue

  # Check the package dependencies
  if [[ -n "$deps" ]]; then
    for dep in $deps; do
      # Check if the dependency is listed in the package list
      is_listed=$(cut -d '#' -f 1 "$PACKAGE_LIST" \
        | sed 's/^[[:space:]]*//' \
        | awk -F '|' -v dep="$dep" \
        '$1 == dep { print true; exit } END { print false }'
      )

      # Check if the dependency is satisfied
      if ! $is_listed && ! is_package_installed "$dep"; then
        log_warning \
          "Package '$package' is missing dependency '$dep', skipping..."
        continue 2
      fi
    done
  fi

  # Add the package to install
  if is_package_installed "$package"; then
    log_warning "Package '$package' is already installed, skipping..."
  elif is_package_available "$package"; then
    log_info "Adding '$package' from official arch repo..."
    arch_packages+=("$package")
  elif is_aur_package_available "$package"; then
    log_info "Adding '$package' from arch user repo..."
    aur_packages+=("$package")
  else
    log_error "Package '$package' is unknown!"
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
  log_warning "No official packages to install, skipping..."
fi

#----------------------#
# install AUR packages #
#----------------------#
if [[ ${#aur_packages[@]} -gt 0 ]]; then
  log_info "Installing AUR packages..."
  if "$aur_helper" "$use_default" -S "${aur_packages[@]}"; then
    log_success "Installed AUR packages."
  else
    log_error "Failed to install AUR packages!"
    exit $EXIT_FAILURE
  fi
else
  log_warning "No AUR packages to install, skipping..."
fi

# End of install_packages.sh
