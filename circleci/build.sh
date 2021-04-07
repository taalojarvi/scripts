#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/kdrag0n/proton-clang  clang
git clone --depth=1 https://github.com/taalojarvi/AnyKernel3 AnyKernel
git clone --depth=1 https://github.com/Stratosphere-Kernel/Stratosphere-Canaries canary
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${KERNEL_DIR}/clang/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_USER="taalojarvi"
export KBUILD_BUILD_HOST="app.circleci.com"
export ARCH=arm64 
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# Make Release notes
function note() {
touch releasenotes.md
echo -e "This is an Automated Early Access build of Stratosphere Kernel. Flash at your own risk!" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Build Information" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Build Name: "$CIRCLE_JOB >> releasenotes.mod
echo -e "Build Number: "$CIRCLE_BUILD_NUM >> releasenotes.md
echo -e "Build URL: "$CIRCLE_BUILD_URL >> releasenotes.md
echo -e "Build Date: $(date +%c)" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Last 10 Commits before Build:-" >> releasenotes.md
echo -e >> releasenotes.md
git log --decorate=auto --pretty=format:'%Creset %f %C(bold blue)<%an>%Creset %n' --graph -n 10 >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Downloads available at https://www.github.com/Stratosphere-Kernel/Stratosphere-Canaries" >> releasenotes.md
cp releasenotes.md canary/
}

# Compiling
function compile() {
    make CC='ccache clang  -Qunused-arguments' O=out/ stratosphere_defconfig
    make -j$(nproc --all) CC='ccache clang  -Qunused-arguments' O=out/
    if ! [ -a "$IMAGE" ]; then
        echo -e "Failed! Check your code"
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 Stratosphere-${TANGGAL}.zip * -x README.md zipsigner.jar LICENSE
    java -jar zipsigner.jar Stratosphere-${TANGGAL}.zip Stratosphere-${TANGGAL}-signed.zip
    cp Stratosphere-${TANGGAL}-signed.zip ../canary
    cd ../canary
}

# Releasing
function release() {
gh release create earlyaccess-${TANGGAL} Stratosphere-${TANGGAL}-signed.zip -F releasenotes.md -p -t "Stratosphere Kernel: Automated Build"
}
note
compile
zipping
release
END=$(date +"%s")
DIFF=$(($END - $START))
