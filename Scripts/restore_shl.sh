#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: install_shell.sh                   |-------/ /-|#
#|------/ /--| Description: Install user shell.           |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-09-28                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-09-28                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf "\033[0;31m[ERROR]\033[0m Failed to source '%s'!\n" \
    "shared_utils.sh" >&2
  exit 1
fi

#----------------#
# get user shell #
#----------------#
if ! get_installed_package "user_shell" "${SHELL_LIST[@]}"; then
  log_error "User shell is not installed!"
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

  # Check the plugin list file
  declare -r PLUGIN_LIST="$SRC_DIR/install_zsh.lst"
  check_file_exist "$PLUGIN_LIST"

  # Add the plugins to install
  while IFS= read -r line; do
    # Skip the empty lines
    [[ -z "$line" ]] && continue

    # Get the plugin name
    plugin=$(echo "$line" | awk -F '/' '{ print $NF }')

    # Clone the plugin
    if [[ "${line:0:4}" == "http" ]] && [[ ! -d "$ZSH_PLUGINS_DIR/$plugin" ]]; then
      print_info "Cloning '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'..."
      if sudo git clone "$line" "$ZSH_PLUGINS_DIR/$plugin"; then
        print_success "Cloned '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'."
      else
        print_error "Failed to clone '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'!"
        exit $EXIT_FAILURE
      fi
    fi

    # Add the zsh plugin
    if [[ "$plugin" == "zsh-completions" ]]
        && ! grep -q 'fpath+=.*plugins/zsh-completions/src' "$ZSHRC"; then
      completions_fix=$'\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src'
    else
      plugins+=("$plugin")
    fi
  done < <(
    # Remove comments and trim the leading/trailing whitespace
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
if [[ "$(grep "/$USER:" "/etc/passwd" \
      | awk -F '/' '{ print $NF }')" != "$user_shell" ]]; then
  print_info "Setting '$user_shell' as default shell..."
  if chsh -s "$(which "$user_shell")"; then
    print_success "Set '$user_shell' as default shell."
  else
    print_error "Failed to set '$user_shell' as default shell!"
    exit $EXIT_FAILURE
  fi
else
  print_warning "Shell '$user_shell' is already set as default, skipping..."
fi

# End of install_shell.sh
