#!/bin/bash
set -euo pipefail
# SPDX-License-Identifier: Apache-2.0
# Script for Updating Kernel for WSL2
# Last Updated on 18 May 2024
# Copyright (C) Karthik Sreedevan V <sreedevan05@gmail.com>

# Configuration
KERNEL_URL="https://github.com/taalojarvi/Stratosphere-Kernel-WSL2/releases/download/mainline/bzImage-zen2"
KERNEL_PATH="/mnt/c/Users/sreed/bzImage"
FORCE_CONSOLE=0

# Colors
declare -A colors=(
    [blue]='\033[0;34m'
    [cyan]='\033[0;36m'
    [yellow]='\033[0;33m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [nocol]='\033[0m'
)

DIVIDER="${colors[blue]}***********************************************${colors[nocol]}"
TITLE="WSL Kernel Updater"
BACKTITLE="Copyright(C) 2024 Karthik Sreedevan V"

banner() {
    printf "\n\n%s\n" "$DIVIDER"
    printf "${colors[yellow]}	    WSL2 Kernel Updater\n"
    printf "${colors[yellow]}	  by taalojarvi@github.com\n"
    printf "%s\n\n\n\n" "$DIVIDER"
}

error_handler() {
    local error_messages=(
        "Download Failed! Please check your internet connection."
        "Remote kernel image not found! Aborting."
        "Local kernel image not found! Please check your KERNEL_PATH."
        "Checksum error! Aborting."
        "Copying kernel image failed! Please check your KERNEL_PATH."
        "Downloaded kernel image appears to be corrupt! Halting."
        "Checksum mismatch. Please check your internet connection."
    )
    local message="${error_messages[$1-1]:-Achievement Unlocked! [How did we get here?]}"

    if command -v dialog &> /dev/null; then
        dialog --title "$TITLE" --backtitle "$BACKTITLE" --msgbox "$message" 5 75
    else
        printf "${colors[red]}\n%s\n\n" "$message"
    fi

    [[ $1 -eq 1 || $1 -eq 5 || $1 -eq 6 || $1 -eq 7 ]] && exit 1
}

get_kernel_version() {
    file -b "$1" | grep -o 'version [^ ]*' | cut -d ' ' -f 2
}

update_kernel() {
    local local_sha remote_sha

    banner
    printf "${colors[cyan]}For a better experience, install the dialog package.${colors[nocol]}\n\n"
    printf "${colors[cyan]}*Checking for updates. Please wait!${colors[nocol]}\n\n"

    local_sha=$(sha256sum "$KERNEL_PATH" | cut -d ' ' -f 1) || error_handler 4
    remote_sha=$(curl -Ls "${KERNEL_URL}.sha256" | cut -d ' ' -f 1)

    if [[ "$local_sha" != "$remote_sha" ]]; then
        printf "${colors[cyan]}*Downloading latest kernel image${colors[nocol]}\n\n"
        wget -q --show-progress "$KERNEL_URL" -O bzImage || error_handler 1

        printf "\n${colors[cyan]}*Remote kernel image version is %s${colors[nocol]}\n" "$(get_kernel_version bzImage)"
        printf "${colors[cyan]}*Local kernel image version is %s${colors[nocol]}\n" "$(get_kernel_version "$KERNEL_PATH")"

        local update_sha_local
        update_sha_local=$(sha256sum bzImage | cut -d ' ' -f 1) || error_handler 4

        [[ "$update_sha_local" != "$remote_sha" ]] && error_handler 7

        printf "\n${colors[blue]}*An update was found! Installing...${colors[nocol]}\n\n"
        mv -f bzImage "$KERNEL_PATH" || error_handler 5
        printf "\n${colors[green]}*Kernel was successfully updated! Please restart your WSL2 instance.${colors[nocol]}\n\n"
    else
        printf "\n${colors[green]}*Kernel is up to date! No actions were taken.${colors[nocol]}\n\n"
        rm -f bzImage
    fi
}

update_kernel_dialog() {
    local local_sha remote_sha

    clear
    dialog --title "$TITLE" --backtitle "$BACKTITLE" --infobox "Checking for updates..." 3 50

    local_sha=$(sha256sum "$KERNEL_PATH" | cut -d ' ' -f 1) || error_handler 4
    remote_sha=$(curl -Ls "${KERNEL_URL}.sha256" | cut -d ' ' -f 1)

    if [[ "$local_sha" != "$remote_sha" ]]; then
        wget --progress=dot "$KERNEL_URL" -O bzImage 2>&1 | 
            grep "%" | sed -u -e "s,\.,,g" | awk '{print $2}' | sed -u -e "s,\%,,g" |
            dialog --gauge "Downloading update. Please wait!" 7 50 || error_handler 1

        clear
        local remote_ver
        remote_ver=$(get_kernel_version bzImage) || error_handler 2
        local update_sha_local
        update_sha_local=$(sha256sum bzImage | cut -d ' ' -f 1) || error_handler 4

        [[ "$update_sha_local" != "$remote_sha" ]] && error_handler 7

        dialog --title "$TITLE" --backtitle "$BACKTITLE" --infobox "An update was found! Installing..." 3 50
        mv -f bzImage "$KERNEL_PATH" || error_handler 5
        clear
        dialog --title "$TITLE" --backtitle "$BACKTITLE" --msgbox "Update Completed. Kernel version is $remote_ver" 5 68
    else
        clear
        dialog --title "$TITLE" --backtitle "$BACKTITLE" --msgbox "Kernel is up to date! No actions were taken." 5 50
        rm -f bzImage
    fi
}

main() {
    if command -v dialog &> /dev/null && [[ $FORCE_CONSOLE -eq 0 ]]; then
        update_kernel_dialog
    else
        update_kernel
    fi
}

main
