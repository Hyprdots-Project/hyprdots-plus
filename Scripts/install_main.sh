#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_main.sh                    |-------/ /-|#
#|------/ /--| Description: Main-installation script.     |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-30                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-30                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#
 
#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#----------------------#
# prepare package list #
#----------------------#
shift $((OPTIND - 1))
readonly CUSTOM_PACKAGES="${1:-}"
readonly PACKAGE_LIST="$SRC_DIR/install_packages.lst"
readonly PACKAGES_TMP="$SRC_DIR/packages_tmp.lst"

check_file_exists "$PACKAGE_LIST"
cp "$PACKAGE_LIST" "$PACKAGES_TMP"

if [[ -f "$CUSTOM_PACKAGES" ]]; then
  cat "$CUSTOM_PACKAGES" >> "$PACKAGES_TMP"
fi

#--------------------------------#
# add nvidia drivers to the list #
#--------------------------------#
if is_nvidia_detected; then
  while read -r kernel; do
    echo "$kernel-headers" >> "$PACKAGES_TMP"
  done < <(cat /usr/lib/modules/*/pkgbase)

  detect_nvidia --drivers >> "$PACKAGES_TMP"
fi

detect_nvidia --verbose

#------------------#
# install packages #
#------------------#
"$SRC_DIR/install_packages.sh" "$PACKAGES_TMP"
rm "$PACKAGES_TMP"

# End of install_main.sh
