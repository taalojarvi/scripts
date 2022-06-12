#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Script for Updating Kernel for WSL2
# Copyright (C) Karthik Sreedevan V <sreedevan05@gmail.com>

# Colours and Graphics
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
green='\e[32m'
DIVIDER="$blue***********************************************$nocol"

# Add link to the Github Releases
# Use latest specified release format as stipulated in https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
export KERNEL_URL=https://github.com/Locietta/xanmod-kernel-WSL2/releases/latest/download/bzImage

# Modify with the path to your bzImage
export KERNEL_PATH=/mnt/c/Users/sreed/bzImage

#*************************************
# Careful modifying beyond this point!
#*************************************
function banner() {
printf "\n\n$cyan$DIVIDER$nocol\n"
printf "$yellow	    WSL2 Kernel Updater\n"
printf "$yellow	  by taalojarvi@github.com\n"
printf "$cyan$DIVIDER$nocol\n\n\n\n"
}

function updater() {
printf "$cyan *Downloading latest kernel image$nocol\n\n" 
wget -r -q --show-progress "$KERNEL_URL" -O bzImage || printf "$red *Download failed! Check your internet Connection connection$nocol\n\n"
printf "\n$cyan *Remote kernel image version is $(file -b bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2 || printf "$red *Error! File not found!$nocol\n\n")$nocol\n" 
printf "$cyan *Local kernel image version is $(file -b $KERNEL_PATH| grep -o 'version [^ ]*' | cut -d ' ' -f 2 || printf "$red *Error! File not found!$nocol\n\n")$nocol\n"
export UPDATE_SHA=$(sha256sum bzImage | cut -d ' ' -f 1 || printf "$red *Error! Checksum failed!$nocol\n" )
export CURRENT_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || printf "$red *Error! Checksum failed!$nocol\n")

if [ "$UPDATE_SHA" = "$CURRENT_SHA" ]; then
		printf "\n$green *Kernel is up to date! No actions were taken.$nocol\n\n" 
		rm bzImage
	else
		printf "\n$blue *An update was found! Installing...$nocol\n\n"
		mv -f -v bzImage "$KERNEL_PATH" || printf "$red *Copying failed!$nocol\n\n"
		printf "\n$green *Kernel was succesfully updated! Please restart your WSL2 instance.$nocol\n\n"
fi
}

banner
updater
