#!/usr/bin/env bash
#|---/ /+-------------------------------------------+---/ /|#
#|--/ /-| Script to install aur helper, yay or paru |--/ /-|#
#|-/ /--| Prasanth Rangan                           |-/ /--|#
#|/ /---+-------------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

if chk_list "aurhlpr" "${aurList[@]}"; then
    echo -e "\033[0;32m[AUR]\033[0m detected // ${aurhlpr}"
    exit 0
fi

aurhlpr="${1:-yay}"

if [ -d "$HOME/.local/src/${aurhlpr}" ]; then
    echo "~/.local/src/${aurhlpr} directory exists..."
    rm -rf "$HOME/.local/src/${aurhlpr}"
else
    mkdir "$HOME/.local/src/${aurhlpr}"
    echo -e "[Desktop Entry]\nIcon=default-folder-git" > "$HOME/.local/src/${aurhlpr}/.directory"
    echo "~/.local/src/${aurhlpr} directory created..."
fi

if pkg_installed git; then
    git clone "https://aur.archlinux.org/${aurhlpr}.git" "$HOME/.local/src/${aurhlpr}"
else
    echo "git dependency is not installed..."
    exit 1
fi

cd "$HOME/.local/src/${aurhlpr}"
makepkg ${use_default} -si

if [ $? -eq 0 ]; then
    echo "${aurhlpr} aur helper installed..."
    exit 0
else
    echo "${aurhlpr} installation failed..."
    exit 1
fi
