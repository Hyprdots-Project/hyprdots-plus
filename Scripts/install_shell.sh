#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_shell.sh                   |-------/ /-|#
#|------/ /--| Description: Install the user shell.       |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-18                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-18                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script installs the specified user shell, sets it as
the default shell for the current user, and (if zsh is chosen)
installs the plugins listed in 'install_zsh.lst'.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' "\033[0;31m[ERROR]\033[0m Failed to source the 'shared_utils.sh' file!" >&2
  exit 1
fi

#----------------#
# get user shell #
#----------------#
if ! get_installed_package "user_shell" "${shell_list[@]}"; then
  print_error "The user shell is not installed!"
  exit $EXIT_FAILURE
fi

#---------------------#
# install zsh plugins #
#---------------------#
if is_package_installed "zsh" && is_package_installed "oh-my-zsh-git"; then
  # Set the zsh variables
  declare -r ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  declare -r ZSH_PATH="/usr/share/oh-my-zsh"
  declare -r ZSH_PLUGINS_DIR="$ZSH_PATH/custom/plugins"
  declare -a plugins=()
  completions_fix=""

  # Check the plugins list file
  declare -r PLUGINS_LIST="$SRC_DIR/install_zsh.lst"
  check_file_exists "$PLUGINS_LIST"

  # Get the zsh plugins
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Get the zsh plugin
    plugin=$(echo "$line" | awk -F '/' '{ print $NF }')

    # Clone the zsh plugin
    if [[ "${line:0:4}" == "http" ]] && [[ ! -d "$ZSH_PLUGINS_DIR/$plugin" ]]; then
      print_info "Cloning the '$plugin' zsh plugin to '$ZSH_PLUGINS_DIR/$plugin'..."
      if sudo git clone "$line" "$ZSH_PLUGINS_DIR/$plugin"; then
        print_success "Cloned the '$plugin' zsh plugin to '$ZSH_PLUGINS_DIR/$plugin'."
      else
        print_error "Failed to clone the '$plugin' zsh plugin to '$ZSH_PLUGINS_DIR/$plugin'!"
        exit $EXIT_FAILURE
      fi
    fi

    # Add the zsh plugin
    if [[ "$plugin" == "zsh-completions" ]] && ! grep -q 'fpath+=.*plugins/zsh-completions/src' "$ZSHRC"; then
      completions_fix=$'\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src'
    else
      plugins+=("$plugin")
    fi
  done < <(
    # Remove inline comments and trim whitespace
    cut -d "#" -f 1 "$PLUGINS_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  )

  # Install the zsh plugins
  print_info "Installing the '${plugins[*]}' zsh plugins..."
  if sed -i "/^plugins=/c\plugins=(${plugins[*]})$completions_fix" "$ZSHRC"; then
    print_success "Installed the '${plugins[*]}' zsh plugins."
  else
    print_error "Failed to install the '${plugins[*]}' zsh plugins!"
    exit $EXIT_FAILURE
  fi
fi

#----------------#
# set user shell #
#----------------#
if [[ "$(grep "/$USER:" "/etc/passwd" | awk -F '/' '{ print $NF }')" != "$user_shell" ]]; then
  print_info "Setting '$user_shell' as the default shell..."
  if chsh -s "$(which "$user_shell")"; then
    print_success "Set '$user_shell' as the default shell."
  else
    print_error "Failed to set '$user_shell' as the default shell!"
    exit $EXIT_FAILURE
  fi
else
  print_warning "The '$user_shell' is already set as the default shell, skipping..."
fi

# End of install_shell.sh
