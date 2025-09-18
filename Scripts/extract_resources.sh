#!/usr/bin/env bash
#|--------/ /+---------------------------------------------+--------/ /|#
#|-------/ /-| Script: extract_resources.sh                |-------/ /-|#
#|------/ /--| Description: Extract the resource archives. |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com)  |-----/ /---|#
#|----/ /----|---------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                                |---/ /-----|#
#|--/ /------| Created: 2025-09-18                         |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-18                    |-/ /-------|#
#|/ /--------+---------------------------------------------+/ /--------|#

: <<'DOC'
This script reads a list of resource archives from 'extract_resources.lst',
iterates through them, and extracts each resource to its target directory.
It skips empty lines, line comments, and rebuilds the font cache at the end.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' "\033[0;31m[ERROR]\033[0m Failed to source the 'shared_utils.sh' file!" >&2
  exit 1
fi

#--------------------------#
# check resource list file #
#--------------------------#
declare -r RESOURCE_LIST="$SRC_DIR/extract_resources.lst"
check_file_exists "$RESOURCE_LIST"

#---------------------------#
# extract resource archives #
#---------------------------#
while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Get the resource and its target directory
  resource="$(echo "$line" | awk -F '|' '{ print $1 }')"
  target_dir="$(echo "$line" | awk -F '|' '{ print $2 }' | envsubst)"

  # Ensure the resource target directory exists
  [[ ! -d "$target_dir" ]] && sudo mkdir -p "$target_dir"

  # Check the resource archive
  resource_archive="$CLONE_DIR/Source/arcs/$resource.tar.gz"
  if [[ ! -f "$resource_archive" ]]; then
    print_error "The '$resource_archive' resource archive does not exist!"
    exit $EXIT_FAILURE
  fi

  # Extract the resource archive
  print_info "Extracting the '$resource_archive' resource archive to '$target_dir'..."
  if sudo tar -xzf "$resource_archive" -C "$target_dir"; then
    print_success "Extracted the '$resource_archive' resource archive to '$target_dir'."
  else
    print_error "Failed to extract the '$resource_archive' resource archive to '$target_dir'!"
    exit $EXIT_FAILURE
  fi
done < <(
  # Remove inline comments and trim whitespace
  cut -d "#" -f 1 "$RESOURCE_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

#--------------------#
# rebuild font cache #
#--------------------#
print_info "Rebuilding the font cache..."
if fc-cache -f; then
  print_success "Rebuilt the font cache."
else
  print_error "Failed to rebuild the font cache!"
  exit $EXIT_FAILURE
fi

# End of extract_resources.sh
