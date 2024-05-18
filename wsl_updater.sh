#!/bin/bash -e
# SPDX-License-Identifier: Apache-2.0
# Script for Updating Kernel for WSL2
# Last Updated on 18 May 2024
# Copyright (C) Karthik Sreedevan V <sreedevan05@gmail.com>

# Used by blam() to kill main process from within a subprocess
set -o pipefail
trap "exit 1" TERM
export TOP_PID=$$

# Set this to 1 to force console output
FORCE_CONSOLE=0

# Colours and Graphics
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
green='\e[32m'
DIVIDER="$blue***********************************************$nocol"
TITLE="WSL Kernel Updater"
BACKTITLE="Copyright(C) 2024 Karthik Sreedevan V"

# Add link to the Github Releases
# Use latest specified release format as stipulated in https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
KERNEL_URL=https://github.com/Locietta/xanmod-kernel-WSL2/releases/latest/download/bzImage-x64v3

# Modify with the path to your bzImage
KERNEL_PATH=/mnt/c/Users/sreed/bzImage

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

# Macros to generate TUI with dialog
function digmsg(){
dialog --title "$TITLE" --backtitle "$BACKTITLE" --msgbox "$1" $2 $3
}

function digguage() {
dialog --title "$TITLE" --backtitle "$BACKTITLE" --gauge "$1" $2 $3 $4
}

function diginfo() {
dialog --title "$TITLE" --backtitle "$BACKTITLE" --infobox "$1" $2 $3
}

# Command-fail state handler
function blam() {
if [[ $(command -v dialog) ]]; then
	case "$1" in
		1) clear && digmsg "Download Failed! Please check your internet connection." 5 75
	   	   exit 1
   	   	   ;;
		2) clear && digmsg "Remote kernel image not found! Aborting." 5 75
   	   	   kill -s TERM $TOP_PID
   	   	   ;;
		3) clear && digmsg "Local kernel image not found! Please check your KERNEL_PATH." 5 75
   	   	   kill -s TERM $TOP_PID
   	   	   ;;
		4) clear && digmsg "SHA256 failed! Aborting." 5 75
  	   	   kill -s TERM $TOP_PID
  	   	   ;;
		5) clear && digmsg "Copying kernel image failed! Please check your KERNEL_PATH." 5 75
		   exit 1
		   ;;
		6) clear && digmsg "Downloaded kernel image appears to be corrupt! Halting." 5 75
		   exit 1
		   ;;
		*) clear && digmsg "Achievement Unlocked! [How did we get here?]" 5 75
		   kill -s TERM $TOP_PID
		   ;;
	esac
else
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
		6) printf "$red \n *Downloaded kernel image appears to be corrupt! Halting.$nocol\n\n"
		   exit 1
		   ;;
		*) printf "$red \n *Achievement Unlocked! [How did we get here?] $nocol\n\n"
		   kill -s TERM $TOP_PID
		   ;;
	esac
fi
}

# updater function
function updater() {
banner
printf "$cyan For a better experience, install the dialog package.$nocol\n\n"
printf "$cyan *Checking for updates. Please wait!$nocol\n\n"
UPDATE_SHA_REMOTE=$(curl -Ls https://github.com/Locietta/xanmod-kernel-WSL2/releases/latest/download/bzImage-x64v3.sha256 | cut -d ' ' -f 1)
LOCAL_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4)

if [ "$LOCAL_SHA" != "$UPDATE_SHA_REMOTE" ] ; then
	printf "$cyan *Downloading latest kernel image$nocol\n\n"
	wget -r -q --show-progress "$KERNEL_URL" -O bzImage || blam 1
	printf "\n$cyan *Remote kernel image version is $(file -b bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2)" || blam 2
	printf "\n$cyan *Local kernel image version is $(file -b $KERNEL_PATH| grep -o 'version [^ ]*' | cut -d ' ' -f 2)" || blam 3

	UPDATE_SHA_LOCAL=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )


	if [ "$UPDATE_SHA_LOCAL" != "$UPDATE_SHA_REMOTE" ]; then
		blam 9
	fi

	printf "\n\n$blue *An update was found! Installing...$nocol\n\n"
	mv -f -v bzImage "$KERNEL_PATH" || blam 5
	printf "\n$green *Kernel was succesfully updated! Please restart your WSL2 instance.$nocol\n\n"

else
		printf "\n$green *Kernel is up to date! No actions were taken.$nocol\n\n"
		rm -f bzImage
fi
}

# Update with dialog boxes
function digtater() {
clear && diginfo "Checking for updates..." 3 50

LOCAL_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4 )
UPDATE_SHA_REMOTE=$(curl -Ls https://github.com/Locietta/xanmod-kernel-WSL2/releases/latest/download/bzImage-x64v3.sha256 | cut -d ' ' -f 1)

if [ "$LOCAL_SHA" != "$UPDATE_SHA_REMOTE" ]; then
	wget --progress=dot "$KERNEL_URL" -O bzImage 2>&1 | grep "%" | sed -u -e "s,\.,,g" | awk '{print $2}' | sed -u -e "s,\%,,g"  | dialog --gauge "Downloading update. Please wait!" 7 50   || blam 1
	clear
	REMOTE_VER=$(file -b bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2 || blam 2)
	UPDATE_SHA_LOCAL=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )


		if [ "$UPDATE_SHA_LOCAL" != "$UPDATE_SHA_REMOTE" ]; then
			blam 9
		fi

		clear && diginfo "An update was found! Installing..." 3 50
		mv -f bzImage "$KERNEL_PATH" || blam 5
		clear && digmsg "Update Completed. Kernel version is $REMOTE_VER" 5 68
else
	clear && digmsg "Kernel is up to date! No actions were taken." 5 50
	rm -f bzImage
fi
}

function init(){
if [ $(command -v dialog) ] && [ $FORCE_CONSOLE == 0 ]; then
	digtater
	clear
	exit 0
else
	updater
	exit 0
fi
}

init
