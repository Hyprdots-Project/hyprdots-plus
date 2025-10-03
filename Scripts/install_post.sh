#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_post.sh                    |-------/ /-|#
#|------/ /--| Description: Post-installation script.     |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.1                               |---/ /-----|#
#|--/ /------| Created: 2025-10-01                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-02                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

# TODO: DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
  exit 1
fi

#----------------#
# configure sddm #
#----------------#
if is_package_installed "sddm"; then
  # Ensure the config directory exists
  [[ ! -d "/etc/sddm.conf.d" ]] && sudo mkdir -p "/etc/sddm.conf.d"

  # Check if sddm is already configured
  if [[ ! -f "/etc/sddm.conf.d/kde_settings.t2.bkp" ]]; then
    log_info "Configuring 'sddm'..."

    # Get the user choice
    printf "Select sddm theme:\n[1] Candy\n[2] Corners\n"
    read -rp " :: Enter a number (default = 2): " sddm_option

    # Get the theme name
    case $sddm_option in
      1) sddm_theme="Candy" ;;
      *) sddm_theme="Corners" ;;
    esac

    # Set the theme
    sudo tar -xzf "$CLONE_DIR/Source/arcs/Sddm_$sddm_theme.tar.gz" \
      -C "/usr/share/sddm/themes"
    sudo touch "/etc/sddm.conf.d/kde_settings.conf"
    sudo cp "/etc/sddm.conf.d/kde_settings.conf" \
      "/etc/sddm.conf.d/kde_settings.t2.bkp"
    sudo cp "/usr/share/sddm/themes/$sddm_theme/kde_settings.conf" \
      "/etc/sddm.conf.d/"
  else
    log_warning "Package 'sddm' is already configured, skipping..."
  fi

  # Set the user icon
  if [[ ! -f "/usr/share/sddm/faces/$USER.face.icon" ]] \
    && [[ -f "$CLONE_DIR/Source/misc/$USER.face.icon" ]]; then
    log_info "Setting '$USER.face.icon' as user icon..."
    if sudo cp "$CLONE_DIR/Source/misc/$USER.face.icon" \
      "/usr/share/sddm/faces"; then
      log_success "Set '$USER.face.icon' as user icon."
    else
      log_error "Failed to set '$USER.face.icon' as user icon!"
      exit $EXIT_FAILURE
    fi
  fi
else
  log_warning "Package 'sddm' is not installed, skipping configuration..."
fi

#-------------------#
# configure dolphin #
#-------------------#
if is_package_installed "dolphin" && is_package_installed "xdg-utils"; then
  # Check if dolphin is already set as the default file explorer
  if [[ "$(xdg-mime query default inode/directory)" \
        != "org.kde.dolphin.desktop" ]]; then
    log_info "Setting 'dolphin' as default file explorer..."
    # Set dolphin as the default file explorer
    if xdg-mime default org.kde.dolphin.desktop inode/directory; then
      log_success "Set 'dolphin' as default file explorer."
    else
      log_error "Failed to set 'dolphin' as default file explorer!"
      exit $EXIT_FAILURE
    fi
  else
    log_warning "Package 'dolphin' is already set as default file explorer, skipping..."
  fi
else
  log_warning "Package 'dolphin' is not installed, skipping configuration..."
fi

#----------------------#
# configure user shell #
#----------------------#
"$SRC_DIR/configure_shell.sh"

# End of install_post.sh
