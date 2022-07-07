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
TITLE="WSL Kernel Updater"
BACKTITLE="Copyright(C) 2022 Karthik Sreedevan V"
# Not yet implemented
WHIPARGS='--title "WSL Kernel Updater" --backtitle "Copyright(C) 2022 Karthik Sreedevan V"'

# Add link to the Github Releases
# Use latest specified release format as stipulated in https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
KERNEL_URL=https://github.com/Locietta/xanmod-kernel-WSL2/releases/latest/download/bzImage

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

# Macros to generate TUI with whiptail
function whipmsg(){
whiptail --title "$TITLE" --backtitle "$BACKTITLE" --msgbox "$1" $2 $3
}

function whipgauge() {
whiptail --title "$TITLE" --backtitle "$BACKTITLE" --gauge "$1" $2 $3 $4
}

function whipinfo() {
whiptail --title "$TITLE" --backtitle "$BACKTITLE" --infobox "$1" $2 $3
}

# Command-fail state handler
function blam() {
if [[ $(command -v whiptail) ]]; then
	case "$1" in
		1) clear && whipmsg "Download Failed! Please check your internet connection." 5 75 
	   	   exit 1
   	   	   ;;
		2) clear && whipmsg "Remote kernel image not found! Aborting." 5 75 
   	   	   kill -s TERM $TOP_PID
   	   	   ;;
		3) clear && whipmsg "Local kernel image not found! Please check your KERNEL_PATH." 5 75 
   	   	   kill -s TERM $TOP_PID
   	   	   ;;
		4) clear && whipmsg "SHA256 failed. Aborting." 5 75 
  	   	   kill -s TERM $TOP_PID
  	   	   ;;
		5) clear && whipmsg "Copying kernel image failed. Please check your KERNEL_PATH" 5 75 
		   exit 1
		   ;;
		*) clear && whipmsg "Achievement Unlocked! [How did we get here?]" 5 75 
		   kill -s TERM $TOP_PID
		   ;;
	esac
elif [[ $(command -v dialog) ]]; then
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
		4) clear && digmsg "SHA256 failed. Aborting." 5 75 
  	   	   kill -s TERM $TOP_PID
  	   	   ;;
		5) clear && digmsg "Copying kernel image failed. Please check your KERNEL_PATH" 5 75 
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
		*) printf "$red \n *Achievement Unlocked! [How did we get here?] $nocol\n\n"
		   kill -s TERM $TOP_PID
		   ;;
	esac
fi
}

# updater function
function updater() {
banner
printf "$cyan *Downloading latest kernel image$nocol\n\n"
wget -r -q --show-progress "$KERNEL_URL" -O bzImage || blam 1

printf "\n$cyan *Remote kernel image version is $(file -b bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2 || blam 2)" || blam 2
printf "\n$cyan *Local kernel image version is $(file -b $KERNEL_PATH| grep -o 'version [^ ]*' | cut -d ' ' -f 2 || blam 3)" || blam 3

UPDATE_SHA=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )
CURRENT_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4)

if [ "$UPDATE_SHA" = "$CURRENT_SHA" ]; then
		printf "\n$green *Kernel is up to date! No actions were taken.$nocol\n\n"
		rm bzImage
	else
		printf "\n\n$blue *An update was found! Installing...$nocol\n\n"
		mv -f -v bzImage "$KERNEL_PATH" || blam 5
		printf "\n$green *Kernel was succesfully updated! Please restart your WSL2 instance.$nocol\n\n"
fi
}

# Update with dialog boxes
function digtater() {
clear && diginfo "Checking for updates..." 3 50
wget -r -q "$KERNEL_URL" -O bzImage || blam 1
UPDATE_SHA=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )
CURRENT_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4 )

	if [ "$UPDATE_SHA" = "$CURRENT_SHA" ]; then
		clear && digmsg "Kernel is up to date! No actions were taken." 5 50
		rm bzImage
	else
		clear && diginfo "An update was found! Installing..." 3 50
		mv -f bzImage "$KERNEL_PATH" || blam 5
		clear && digmsg "Update completed!" 5 50
	fi
}

# Update with whiptail TUI
function whipdater(){
clear && whipinfo "Checking for updates..." 7 50 
wget -r -q "$KERNEL_URL" -O bzImage || blam 1
UPDATE_SHA=$(sha256sum bzImage | cut -d ' ' -f 1 || blam 4 )
CURRENT_SHA=$(sha256sum $KERNEL_PATH | cut -d ' ' -f 1 || blam 4 )

	if [ "$UPDATE_SHA" = "$CURRENT_SHA" ]; then
		clear && whipmsg "Kernel is up to date! No actions were taken." 7 50
		rm bzImage
	else
		clear && whipinfo "An update was found! Installing..." 7 50
		mv -f bzImage "$KERNEL_PATH" || blam 5
		clear && whipmsg "Update completed!" 7 50
	fi
}

function init(){
if [[ $(command -v dialog) ]]; then
	digtater
elif [[ $(command -v whiptail) ]]; then
	TERM=linux #Workaround for whiptail --infobox bug
	whipdater
else
	updater
fi
}

init
