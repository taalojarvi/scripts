#!/bin/bash -e
# SPDX-License-Identifier: Apache-2.0
# Script for Updating Kernel for WSL2
# Last Updated on 27th June 2022 03:49 PM IST
# Copyright (C) Karthik Sreedevan V <sreedevan05@gmail.com>

# Used by blam() to kill main process from within a subprocess
set -o pipefail
trap "exit 1" TERM
export TOP_PID=$$

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

# Graphic displayed on execution 
function banner() { 
printf "\n\n$cyan$DIVIDER$nocol\n"
printf "$yellow	    WSL2 Kernel Updater\n"
printf "$yellow	  by taalojarvi@github.com\n"
printf "$cyan$DIVIDER$nocol\n\n\n\n"
}

# Command-fail state handler
function blam() {
case "$1" in
	1) printf "$red \n *Download Failed! Please check your internet connection.$nocol\n\n"
	   exit 1
	   ;;
	2) printf "$red \n *Remote kernel image not found! Aborting.$nocol\n\n" 
	   kill -s TERM $TOP_PID
	   ;;
	3) printf "$red \n *Local kernel image not found! Please check your KERNEL_PATH.$nocol\n\n" 
	   kill -s TERM $TOP_PID
	   ;;
	4) printf "$red \n *SHA256 failed. Aborting.$nocol\n\n"
	   kill -s TERM $TOP_PID
	   ;;
	5) printf "$red \n *Copying kernel image failed. Please check your KERNEL_PATH$nocol\n\n"
	   exit 1
	   ;;
	*) printf "$red \n *Achievement Unlocked! [How did we get here?] $nocol\n\n"
	   kill -s TERM $TOP_PID
	   ;;
esac
}

# updater function
function updater() {
printf "$cyan *Downloading latest kernel image$nocol\n\n" 
wget -r -q --show-progress "$KERNEL_URL" -O bzImage || blam 1

printf "\n$cyan *Remote kernel image version is $(file -b bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2 || blam 2)" || blam 2
printf "\n$cyan *Local kernel image version is $(file -b $KERNEL_PATH| grep -o 'version [^ ]*' | cut -d ' ' -f 2 || blam 3)" || blam 3

export UPDATE_SHA=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )
export CURRENT_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4)

if [ "$UPDATE_SHA" = "$CURRENT_SHA" ]; then
		printf "\n$green *Kernel is up to date! No actions were taken.$nocol\n\n" 
		rm bzImage
	else
		printf "\n\n$blue *An update was found! Installing...$nocol\n\n"
		mv -f -v bzImage "$KERNEL_PATH" || blam 5
		printf "\n$green *Kernel was succesfully updated! Please restart your WSL2 instance.$nocol\n\n"
fi

}

banner
updater
