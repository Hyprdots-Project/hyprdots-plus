#!/usr/bin/env bash
#|--------/ /+---------------------------------------------+--------/ /|#
#|-------/ /-| Script: extract_resources.sh                |-------/ /-|#
#|------/ /--| Description: Extract the resource archives. |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com)  |-----/ /---|#
#|----/ /----|---------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.1                                |---/ /-----|#
#|--/ /------| Created: 2025-09-28                         |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-01                    |-/ /-------|#
#|/ /--------+---------------------------------------------+/ /--------|#

: << 'DOC'
This script reads a list of resource archives from 'extract_resources.lst',
iterates through them, and extracts each resource to its target directory.
It ignores comments and empty lines in the resource list file,
and rebuilds the font cache at the end.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#--------------------------#
# check resource list file #
#--------------------------#
readonly RESOURCE_LIST="$SRC_DIR/extract_resources.lst"
check_file_exists "$RESOURCE_LIST"

#---------------------------#
# extract resource archives #
#---------------------------#
while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Get the resource and its target directory
  IFS="|" read -r resource target_dir <<< "$line"
  target_dir="$(echo "$target_dir" | envsubst)"

  # Ensure the target directory exists
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || {
      log_info "Creating '$target_dir' as root..."
      if sudo mkdir -p "$target_dir"; then
        log_success "Created '$target_dir' as root."
      else
        log_error "Failed to create '$target_dir' as root!"
        exit $EXIT_FAILURE
      fi
    }
  fi

  # Check the resource archive
  resource_archive="$CLONE_DIR/Source/arcs/$resource.tar.gz"
  check_file_exists "$resource_archive"

  # Extract the resource archive
  log_info "Extracting '$resource_archive' to '$target_dir'..."
  if sudo tar --overwrite -xzf "$resource_archive" -C "$target_dir"; then
    log_success "Extracted '$resource_archive' to '$target_dir'."
  else
    log_error "Failed to extract '$resource_archive' to '$target_dir'!"
    exit $EXIT_FAILURE
  fi
done < <(
  # Remove comments and trim leading/trailing whitespace
  cut -d "#" -f 1 "$RESOURCE_LIST" \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

#--------------------#
# rebuild font cache #
#--------------------#
log_info "Rebuilding font cache..."
if sudo fc-cache -f; then
  log_success "Rebuilt font cache."
else
  log_error "Failed to rebuild font cache!"
  exit $EXIT_FAILURE
fi

# End of extract_resources.sh
