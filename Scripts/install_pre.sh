#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_pre.sh                     |-------/ /-|#
#|------/ /--| Description: Pre-installation script.      |------/ /--|#
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

#----------------#
# configure grub #
#----------------#
if is_package_installed "grub" && [[ -f "/boot/grub/grub.cfg" ]]; then
  log_info "Configuring 'grub'..."

  if [[ ! -f "/etc/default/grub.t2.bkp" ]] && \
     [[ ! -f "/boot/grub/grub.t2.bkp" ]]; then

    log_info "Configuring 'grub'..."

    sudo cp "/etc/default/grub" "/etc/default/grub.t2.bkp"
    sudo cp "/boot/grub/grub.cfg" "/boot/grub/grub.t2.bkp"

    if is_nvidia_detected; then
      log_info "Detected 'nvidia', adding special boot options..."
      gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" \
        | cut -d'"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
      sudo sed -i \
        "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"$gcld \
        nvidia_drm.modeset=1\"" "/etc/default/grub"
    fi

    printf "Select grub theme:\n[1] Retroboot (dark)\n[2] Pochita (light)\n"
    read -p " :: Enter a number (default = None) : " grub_option
    case $grub_option in
      1) grub_theme="Retroboot" ;;
      2) grub_theme="Pochita" ;;
      *) grub_theme="None" ;;
    esac

    if [ "$grub_theme" == "None" ]; then
      log_warning "No 'grub' theme selected, skipping..."
      sudo sed -i "s/^GRUB_THEME=/#GRUB_THEME=/g" "/etc/default/grub"
    else
      log_info "Setting 'grub' theme '$grub_theme'..."
      sudo tar -xzf "$CLONE_DIR/Source/arcs/Grub_$grub_theme.tar.gz" \
        -C "/usr/share/grub/themes/"
      sudo sed -i \
        "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved" \
        "/^GRUB_GFXMODE=/c\GRUB_GFXMODE=1280x1024x32,auto" \
        "/^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/$grub_theme/theme.txt\"" \
        "/^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/$grub_theme/theme.txt\"" \
        "/^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" "/etc/default/grub"
    fi

    sudo "grub-mkconfig" -o "/boot/grub/grub.cfg"

    log_success "Configured 'grub'."
  else
    log_warning "Package 'grub' is already configured, skipping..."
  fi
fi

#-------------------#
# configure systemd #
#-------------------#
if is_package_installed "systemd" && is_nvidia_detected && \
   [[ $(bootctl status 2> /dev/null \
     | awk '{if ($1 == "Product:") print $2}') == "systemd-boot" ]]; then

  log_info "Configuring 'systemd'..."

  if [[ $(ls -l /boot/loader/entries/*.conf.t2.bkp 2>/dev/null | wc -l) \
     -ne $(ls -l /boot/loader/entries/*.conf 2> /dev/null | wc -l) ]]; then

    echo "nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
    find "/boot/loader/entries/" -type f -name "*.conf" | while read imgconf; do
      sudo cp "$imgconf" "$imgconf.t2.bkp"
      sdopt=$(grep -w "^options" "$imgconf" \
        | sed 's/\b quiet\b//g' \
        | sed 's/\b splash\b//g' \
        | sed 's/\b nvidia_drm.modeset=.\b//g')
      sudo sed -i "/^options/c$sdopt quiet splash nvidia_drm.modeset=1" "$imgconf"
    done

    log_success "Configured 'systemd'."
  else
    log_warning "Package 'systemd' is already configured, skipping..."
  fi
fi

#------------------#
# configure pacman #
#------------------#
if [[ -f "/etc/pacman.conf" ]] && [[ ! -f "/etc/pacman.conf.t2.bkp" ]]; then
  log_info "Configuring 'pacman'..."

  # Add the enhancements
  sudo cp "/etc/pacman.conf" "/etc/pacman.conf.t2.bkp"
  sudo sed -i '/^#Color/c\Color\nILoveCandy' \
              '/^#VerbosePkgLists/c\VerbosePkgLists' \
              '/^#ParallelDownloads/c\ParallelDownloads = 5' "/etc/pacman.conf"
  sudo sed -i '/^#\[multilib\]/,+1 s/^#//' "/etc/pacman.conf"

  # Refresh the database
  sudo pacman -Syyu
  sudo pacman -Fy

  log_success "Configured 'pacman'."
else
  log_warning "Package 'pacman' is already configured, skipping..."
fi

# End of install_pre.sh
