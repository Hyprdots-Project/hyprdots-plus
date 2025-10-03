#!/usr/bin/env bash
#|--------/ /+--------------------------------------------+--------/ /|#
#|-------/ /-| Script: configure_shell.sh                 |-------/ /-|#
#|------/ /--| Description: Configure the user shell.     |------/ /--|#
#|-----/ /---| Author: Marek Čupr (cupr.marek2@gmail.com) |-----/ /---|#
#|----/ /----|--------------------------------------------|----/ /----|#
#|---/ /-----| Version: 1.0                               |---/ /-----|#
#|--/ /------| Created: 2025-10-03                        |--/ /------|#
#|-/ /-------| Last Updated: 2025-10-03                   |-/ /-------|#
#|/ /--------+--------------------------------------------+/ /--------|#

: << 'DOC'
This script configures the specified user shell and, if zsh is chosen,
it also installs the plugins listed in 'configure_zsh.lst'.
It ignores comments and empty lines in the plugin list file,
and sets the default user shell at the end.
DOC

#-------------------------#
# import shared utilities #
#-------------------------#
if ! source "$(dirname "$(realpath "$0")")/shared_utils.sh"; then
  printf '%b\n' \
    "\033[0;31m[ERROR]\033[0m Failed to source 'shared_utils.sh'!" >&2
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
  readonly ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  readonly ZSH_PATH="/usr/share/oh-my-zsh"
  readonly ZSH_PLUGINS_DIR="$ZSH_PATH/custom/plugins"
  declare -a plugins=()
  completions_fix=""

  # Check the plugin list file
  readonly PLUGIN_LIST="$SRC_DIR/configure_zsh.lst"
  check_file_exists "$PLUGIN_LIST"

  # Get the zsh plugins
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Get the zsh plugin
    plugin=$(echo "$line" | awk -F '/' '{ print $NF }')

    # Clone the zsh plugin
    if [[ "${line:0:4}" == "http" ]] \
       && [[ ! -d "$ZSH_PLUGINS_DIR/$plugin" ]]; then
      log_info "Cloning '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'..."
      if sudo git clone "$line" "$ZSH_PLUGINS_DIR/$plugin"; then
        log_success "Cloned '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'."
      else
        log_error "Failed to clone '$plugin' to '$ZSH_PLUGINS_DIR/$plugin'!"
        exit $EXIT_FAILURE
      fi
    fi

    # Add the zsh plugin
    if [[ "$plugin" == "zsh-completions" ]] \
       && ! grep -q 'fpath+=.*plugins/zsh-completions/src' "$ZSHRC"; then
      completions_fix=$'\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src'
    else
      plugins+=("$plugin")
    fi
  done < <(
    # Remove comments and trim leading/trailing whitespace
    cut -d "#" -f 1 "$PLUGIN_LIST" \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  )

  # Add the zsh plugins
  log_info "Adding plugins '${plugins[*]}'..."
  if sed -i "/^plugins=/c\plugins=(${plugins[*]})$completions_fix" "$ZSHRC"; then
    log_success "Installed plugins '${plugins[*]}'."
  else
    log_error "Failed to install plugins '${plugins[*]}'!"
    exit $EXIT_FAILURE
  fi
fi

#----------------#
# set user shell #
#----------------#
if [[ "$(grep "/$USER:" "/etc/passwd" \
      | awk -F '/' '{ print $NF }')" != "$user_shell" ]]; then
  log_info "Setting '$user_shell' as default shell..."
  if chsh -s "$(which "$user_shell")"; then
    log_success "Set '$user_shell' as default shell."
  else
    log_error "Failed to set '$user_shell' as default shell!"
    exit $EXIT_FAILURE
  fi
else
  log_warning "Shell '$user_shell' is already set as default, skipping..."
fi

# End of configure_shell.sh
