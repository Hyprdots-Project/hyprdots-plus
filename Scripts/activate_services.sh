#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: activate_services.sh               |-------/ /-|#
#|------/ /--| Description: Activate the system services. |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.1                               |---/ /-----|#
#|--/ /------| Created: 2025-09-28                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-01                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script reads a list of system services from 'activate_services.lst',
iterates through them, and activates each service (enables and starts it).
It ignores comments and empty lines in the service list file,
and skips services that are already active.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#-------------------------#
# check service list file #
#-------------------------#
readonly SERVICE_LIST="$SRC_DIR/activate_services.lst"
check_file_exists "$SERVICE_LIST"

#--------------------------#
# activate system services #
#--------------------------#
while IFS= read -r service; do
  # Skip empty lines
  [[ -z "$service" ]] && continue

  # Check if the service is already active
  if systemctl is-active --quiet "$service"; then
    log_warning "Service '$service' is already active, skipping..."
  else
    # Activate the service
    log_info "Activating '$service'..."
    # The '--now' flag both enables and starts the service
    if sudo systemctl enable --now "$service"; then
      log_success "Activated '$service'."
    else
      log_error "Failed to activate '$service'!"
      exit $EXIT_FAILURE
    fi
  fi
done < <(
  # Remove comments and trim leading/trailing whitespace
  cut -d "#" -f 1 "$SERVICE_LIST" \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

# End of activate_services.sh
