#!/bin/bash -e

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Export Environment Variables
export PATH="$(pwd)/proton-clang/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER="Taalojarvi"
export KBUILD_BUILD_HOST="Travis-CI"
export USE_HOST_LEX=yes
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v ccache)

# Kernel details
KERNEL_NAME="Stratosphere"
VERSION="ME"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="NOKIA_SDM660"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE.zip
defconfig=stratosphere_defconfig

# Dirs
BASE_DIR=~/
KERNEL_DIR=$BASE_DIR/android_kernel_nokia_sdm660
ANYKERNEL_DIR=$BASE_DIR/AnyKernel3
KERNEL_IMG=$BASE_DIR/output/arch/arm64/boot/Image.gz-dtb
UPLOAD_DIR=$BASE_DIR/Stratosphere-Canaries


# Create Release Notes
function make_releasenotes()  {
	touch releasenotes.md
	echo -e "This is an Automated Build of Stratosphere Kernel. Flash at your own risk!" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Build Information" >> releasenotes.md
	echo -e >> releasenotes.md
	echo -e "Build Server Name: "$TRAVIS_APP_HOST >> releasenotes.md
	echo -e "Build ID: "$TRAVIS_BUILD_ID >> releasenotes.md
	echo -e "Build URL: "$TRAVIS_BUILD_WEB_URL >> releasenotes.md
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
gh release create ci-$TRAVIS_BUILD_ID $FINAL_ZIP.zip -F releasenotes.md -p -t "Stratosphere Kernel: Automated Build"
cd $KERNEL_DIR
}
