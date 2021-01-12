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
export ZipID=$TRAVIS_BUILD_ID
export KERNEL_IMG=output/arch/arm64/boot/Image.gz-dtb

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
	cp releasenotes.md ~/build/Stratosphere-Kernel/android_kernel_nokia_sdm660/Stratosphere-Canaries
}

# Make defconfig
function make_defconfig()  {
	make stratosphere_defconfig CC=clang O=output/
}

# Make Kernel
function make_kernel  {
	make -j16 CC=clang AR=llvm-ar NM=llvm-nm STRIP=llvm-strip O=output/
# Check if Image.gz-dtb exists. If not, stop executing.
	if ! [ -a $KERNEL_IMG ];
 		then
    		echo -e "An error has occured during compilation. Please check your code."
    		exit 1
  	fi 
}

# Make Flashable Zip
function make_package()  {
	cp output/arch/arm64/boot/Image.gz-dtb AnyKernel3
	cd AnyKernel3
	zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
	mv UPDATE-AnyKernel2.zip Stratosphere-Kernel-$ZipID.zip
	cp Stratosphere-Kernel-$ZipID.zip ~/build/Stratosphere-Kernel/android_kernel_nokia_sdm660/Stratosphere-Canaries
	cd ~/build/Stratosphere-Kernel/android_kernel_nokia_sdm660/Stratosphere-Canaries
}

# Upload Flashable Zip to GitHub Releases <3
function release()  {
gh release create ci-$TRAVIS_BUILD_ID Stratosphere-Kernel-$ZipID.zip -F releasenotes.md -p -t "Stratosphere Kernel: Automated Build"
}
