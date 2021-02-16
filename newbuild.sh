#!/bin/bash -e
BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
DIVIDER="$blue***********************************************$nocol"

# Kernel details
KERNEL_NAME="Stratosphere"
VERSION="Kernel"
DATE=$(date +"%d-%m-%Y-%I-%M")
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE.zip
DEFCONFIG=stratosphere_defconfig

# Dirs and Files
BASE_DIR=$HOME
KERNEL_DIR=$(pwd)
ANYKERNEL_DIR=$BASE_DIR/AnyKernel3
UPLOAD_DIR=$BASE_DIR/Stratosphere-Canaries
TC_DIR=$BASE_DIR/proton-clang
RELEASE_NOTES=$UPLOAD_DIR/releasenotes.md
OUTPUT=$BASE_DIR/output
KERNEL_IMG=$OUTPUT/arch/arm64/boot/Image.gz-dtb
LOG_DIR=$BASE_DIR/logs


# Export Environment Variables
# export PATH="$TC_DIR/bin:$PATH"
PATH="$TC_DIR/bin:$HOME/linaro-gcc/bin${PATH}"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LD_LIBRARY_PATH=$TC_DIR/lib
export KBUILD_BUILD_USER=$USER
export KBUILD_BUILD_HOST=$(hostname)
export USE_HOST_LEX=yes
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v ccache)
export RELEASE_TAG=earlyaccess-$DATE

# !!!!!!!!!!!!!!!!!!!!!!!!!!!
# DO NOT EDIT PAST THIS POINT
# !!!!!!!!!!!!!!!!!!!!!!!!!!!

# Create Release Notes
function make_releasenotes()  {
	touch releasenotes.md
	echo -e "This is an Early Access Build of "$KERNEL_NAME" Kernel. Flash at your own risk!" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Build Information" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Builder: "$KBUILD_BUILD_USER >> releasenotes.md
	echo -e "Machine: "$KBUILD_BUILD_HOST >> releasenotes.md
	echo -e "Build Date: "$DATE >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Last 5 Commits before Build:-" >> releasenotes.md
	git log --decorate=auto --pretty=format:'%C(yellow)%d%Creset %s %C(bold blue)<%an>%Creset %n' --graph -n 10 >> releasenotes.md
	cp releasenotes.md $BASE_DIR/Stratosphere-Canaries
}

# Make defconfig
function make_defconfig()  {
	echo -e " "
	make $DEFCONFIG CC=clang O=$OUTPUT
}

# Make Kernel
function make_kernel  {
	echo -e " "
	make -j$(nproc --all) CC='ccache clang  -Qunused-arguments -fcolor-diagnostics' O=$OUTPUT
# Check if Image.gz-dtb exists. If not, stop executing.
	if ! [ -a $KERNEL_IMG ];
 		then
    		echo -e "$red An error has occured during compilation. Please check your code. $cyan"
    		exit 1
    	else
    		echo -e "$red Kernel built succesfully! $cyan"
  	fi 
}

# Make Flashable Zip
function make_package()  {
	echo -e " "
	cp $KERNEL_IMG $ANYKERNEL_DIR
	cd $ANYKERNEL_DIR
	zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
	mv UPDATE-AnyKernel2.zip $FINAL_ZIP
	cp $FINAL_ZIP $UPLOAD_DIR
	cd $KERNEL_DIR
	
}

# Upload Flashable Zip to GitHub Releases <3
function release()  {
	echo -e " "
	cd $UPLOAD_DIR
	gh release create $RELEASE_TAG $FINAL_ZIP -F releasenotes.md -p -t "Stratosphere Kernel: Personal Build"
	cd $KERNEL_DIR
}

# Make Clean
function make_cleanup()  {
	echo -e $DIVIDER
	echo -e "$cyan    Cleaning out build artifacts. Please wait       "
	echo -e $DIVIDER
	echo -e " "
	make clean CC=clang O=$OUTPUT
	make mrproper CC=clang O=$OUTPUT
}

# Check for Script Artifacts from previous builds
function artifact_check()  {
	echo -e " "
	if [ -f $ANYKERNEL_DIR/*.zip ]; then
		 echo -e "$red Deleting artifacts! $cyan"
		 rm $ANYKERNEL_DIR/*.zip
	else
		echo -e "$red Script did not find stale packages $cyan"
	fi
	
	if [ -f "$ANYKERNEL_DIR/releasenotes.md" ]; then
		echo -e "$red Deleting Artifacts! $cyan"	
		rm $ANYKERNEL_DIR/releasenotes.md
	else
		echo -e "$red Script did not find artifacts in $ANYKERNEL_DIR $cyan"
	fi
	
	if [ -f "$KERNEL_DIR/releasenotes.md" ]; then
		echo -e "$red Deleting Artifacts! $cyan"
		rm $KERNEL_DIR/releasenotes.md	
	else
		echo -e "$red Script did not find artifacts in $KERNEL_DIR. $cyan"
	fi
	
	if [ -f "$ANYKERNEL_DIR/Image.gz-dtb" ]; then
		echo -e "$red Deleting Artifacts! $cyan"
		rm $ANYKERNEL_DIR/Image.gz-dtb
	else
		echo -e "$red Script did not find stale Kernel Image $cyan"
	fi
}

# Update Toolchain Repository
function update_repo()  {
	echo -e " "
	cd $TC_DIR
	git pull origin
	cd $KERNEL_DIR
}

# Open Menuconfig
function make_menuconfig()  {
	echo -e " "
	make menuconfig CC=clang O=$OUTPUT
}

# Clear CCACHE
function clear_ccache  {
	echo -e " "
	ccache -Cz
}

# Regenerate Defconfig
function regen_defconfig()  {
	echo -e " "
	cp $OUTPUT/.config $KERNEL_DIR/arch/arm64/configs/$DEFCONFIG 
	git commit arch/arm64/configs/$DEFCONFIG
}
	
# Menu
function menu()  {
	clear
	echo -e "$yellow What do you want to do?"
	echo -e ""
	echo -e "1: Build Kernel and Release it to Github"
	echo -e "2: Build Clean Kernel but do not release it"
	echo -e "3: Build Dirty Kernel "
	echo -e "4: Make defconfig and open menuconfig"
	echo -e "5: Make defconfig only"
	echo -e "6: Cleanup script artifacts"
	echo -e "7: Clear ccache and reset stats"
	echo -e "8: Regenerate defconfig"
	echo -e "9: Exit script"
	echo -e ""
	echo -e "Awaiting User Input: $red"
	read choice
	
	case $choice in
		1) echo -e $DIVIDER
		   echo -e "$cyan        Building "$KERNEL_NAME "Kernel         "
		   echo -e $DIVIDER
		   update_repo
		   make_cleanup
		   artifact_check
		   make_releasenotes
		   make_defconfig
	 	   make_kernel
	 	   make_package
	 	   release
	 	   artifact_check
	 	   ;;
		2) echo -e $DIVIDER
		   echo -e "$cyan        Building "$KERNEL_NAME "Kernel         "
		   echo -e $DIVIDER
		   make_cleanup
		   artifact_check
		   make_releasenotes
		   make_defconfig
	 	   make_kernel
	 	   make_package 
	 	   artifact_check
	 	   ;;
	 	3) echo -e $DIVIDER
		   echo -e "$cyan        Building "$KERNEL_NAME "Kernel         "
		   echo -e $DIVIDER
	 	   make_defconfig
	 	   make_kernel
	 	   ;;
	 	4) echo -e $DIVIDER
		   echo -e "$cyan        Opening Menuconfig                          "
		   echo -e $DIVIDER
	 	   make_defconfig
	 	   make_menuconfig
	 	   menu
	 	   ;;
	 	5) echo -e $DIVIDER
		   echo -e "$cyan        Generating Defconfig                        "
		   echo -e $DIVIDER
	 	   make_defconfig
	 	   menu
	 	   ;;
	 	6) make_cleanup
	 	   menu
	 	   ;;
	 	7) echo -e $DIVIDER
		   echo -e "$cyan    Clearing CCACHE                            "
		   echo -e $DIVIDER
	 	   clear_ccache
	 	   menu
	 	   ;;
	 	8) echo -e $DIVIDER
		   echo -e "$cyan    Regenerating defconfig. Please wait        "
		   echo -e $DIVIDER
	 	   make_defconfig
	 	   regen_defconfig
	 	   menu
	 	   ;;
	 	9) echo -e "$red Exiting"
	 	   clear
	 	   ;; 
	 	   
	 esac
	
}

menu
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "Script execution completed after $((DIFF/60)) minute(s) and $((DIFF % 60)) seconds"
