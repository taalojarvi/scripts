#!/bin/bash -e
BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="Stratosphere"
VERSION="ME"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="NOKIA_SDM660"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE.zip
defconfig=stratosphere_defconfig

# Dirs and Files
BASE_DIR=~/
KERNEL_DIR=$BASE_DIR/android_kernel_nokia_sdm660
ANYKERNEL_DIR=$BASE_DIR/AnyKernel3
KERNEL_IMG=$BASE_DIR/output/arch/arm64/boot/Image.gz-dtb
UPLOAD_DIR=$BASE_DIR/Stratosphere-Canaries
TC_DIR=$BASE_DIR/proton-clang
RELEASE_NOTES=$UPLOAD_DIR/releasenotes.md

# Export Environment Variables
export PATH="$BASE_DIR/proton-clang/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER="Taalojarvi"
export KBUILD_BUILD_HOST="ASUS-PC"
export USE_HOST_LEX=yes
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v ccache)


# Create Release Notes
function make_releasenotes()  {
	touch releasenotes.md
	echo -e "This is a Personal Build of Stratosphere Kernel. Flash at your own risk!" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Build Information" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Builder: "$KBUILD_BUILD_USER >> releasenotes.md
	echo -e "Machine: "$KBUILD_BUILD_HOST >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Last 5 Commits before Build:-" >> releasenotes.md
	git log --decorate=auto --pretty=reference --graph -n 10 >> releasenotes.md
	cp releasenotes.md $BASE_DIR/Stratosphere-Canaries
}

# Make defconfig
function make_defconfig()  {
	make stratosphere_defconfig CC=clang O=$BASE_DIR/output/
}

# Make Kernel
function make_kernel  {
	make -j$(nproc --all) CC=clang AR=llvm-ar NM=llvm-nm STRIP=llvm-strip O=$BASE_DIR/output/
# Check if Image.gz-dtb exists. If not, stop executing.
	if ! [ -a $KERNEL_IMG ];
 		then
    		echo -e "An error has occured during compilation. Please check your code."
    		exit 1
  	fi 
}

# Make Flashable Zip
function make_package()  {
	cp $BASE_DIR/output/arch/arm64/boot/Image.gz-dtb $ANYKERNEL_DIR
	cd $ANYKERNEL_DIR
	zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
	mv UPDATE-AnyKernel2.zip $FINAL_ZIP.zip
	cp $FINAL_ZIP.zip $UPLOAD_DIR
	cd $KERNEL_DIR
	
}

# Upload Flashable Zip to GitHub Releases <3
function release()  {
cd $UPLOAD_DIR
gh release create pr-$DATE $FINAL_ZIP.zip -F releasenotes.md -p -t "Stratosphere Kernel: Personal Build"
cd $KERNEL_DIR
}

# Make Clean
function make_cleanup()  {

	make clean CC=clang O=$BASE_DIR/output/
	make mrproper CC=clang O=$BASE_DIR/output/
}

# Check for Artifacts from previous builds
function artifact_check()  {
	if [ -f "$UPLOAD_DIR/releasenotes.md" ]; then
		rm $UPLOAD_DIR/releasenotes.md
	elif [ -f "$KERNEL_DIR/releasenotes.md" ]; then
		rm $KERNEL_DIR/releasenotes.md	
	else
		echo -e "No Build Artifacts found! Skipping."
	fi
}

# Update Toolchain Repository
function update_repo()  {
	cd $TC_DIR
	git pull origin
	cd $KERNEL_DIR
}

# Open Menuconfig
function make_menuconfig()  {
	make stratosphere_defconfig CC=clang O=$BASE_DIR/output/
	make menuconfig CC=clang O=$BASE_DIR/output/
	menu
}
# Menu
function menu()  {
	clear
	echo -e "What do you want to do?"
	echo -e ""
	echo -e "1: Build Kernel and Release it"
	echo -e "2: Build Clean Kernel but Do not release it"
	echo -e "3: Build Dirty Kernel "
	echo -e "4: Make defconfig and open menuconfig"
	echo -e "5: Make defconfig only"
	echo -e "6: Cleanup Build Artifacts"
	echo -e ""
	echo -e "Awaiting User Input: "
	read choice
	
	case $choice in
		1) echo -e "Building "$KERNEL_NAME "Kernel" 
		   update_repo
		   make_cleanup
		   make_releasenotes
		   make_defconfig
	 	   make_kernel
	 	   make_package
	 	   release
	 	   ;;
		2) echo -e "Building "$KERNEL_NAME "Kernel" 
		   make_cleanup
		   make_releasenotes
		   make_defconfig
	 	   make_kernel
	 	   make_package 
	 	   ;;
	 	3) echo -e "Building "$KERNEL_NAME "Kernel" 
	 	   make_defconfig
	 	   make_kernel
	 	   ;;
	 	4) echo -e "Opening Menuconfig"
	 	   make_defconfig
	 	   make_menuconfig
	 	   ;;
	 	5) echo -e "Generating configuration from defconfig"
	 	   make_defconfig
	 	   ;;
	 	6) echo -e "Cleaning out build artifacts. Please Wait!"
	 	   make_cleanup
	 	   menu
	 	   ;;
	 esac
	
}

echo -e "Checking for artifacts from previous builds and removing them if necessary"
artifact_check
menu
artifact_check
BUILD_START=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "Script execution completed after $((DIFF/60)) minute(s) and $((DIFF % 60)) seconds"


