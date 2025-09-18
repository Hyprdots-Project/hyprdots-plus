#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: activate_services.sh               |-------/ /-|#
#|------/ /--| Description: Activate the system services. |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-18                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-18                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script reads a list of system services from 'activate_services.lst',
iterates through them, and activates each service (starts and enables).
It skips the already active services, empty lines, and line comments.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' "\033[0;31m[ERROR]\033[0m Failed to source the 'shared_utils.sh' file!" >&2
  exit 1
fi

#-------------------------#
# check service list file #
#-------------------------#
declare -r SERVICE_LIST="$SRC_DIR/activate_services.lst"
check_file_exists "$SERVICE_LIST"

#--------------------------#
# activate system services #
#--------------------------#
while IFS= read -r service; do
  # Skip empty lines
  [[ -z "$service" ]] && continue

  # Check if the system service is already active
  if systemctl is-active --quiet "$service"; then
    print_warning "The '$service' service is already active, skipping..."
  else
    # Activate the system service
    print_info "Activating the '$service' service..."
    # The '--now' flag both enables and starts the service
    if sudo systemctl enable --now "$service"; then
      print_success "Activated the '$service' service."
    else
      print_error "Failed to activate the '$service' service!"
      exit $EXIT_FAILURE
    fi
  fi
done < <(
  # Remove inline comments and trim whitespace
  cut -d "#" -f 1 "$SERVICE_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

# End of activate_services.sh
