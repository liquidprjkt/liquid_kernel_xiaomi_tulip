#!/usr/bin/env bash
echo "Cloning dependencies"
rm -rf AnyKernel
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 https://github.com/IceBreaker2451/AnyKernel3.git AnyKernel
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
export PATH=$KERNEL_DIR/clang/bin:$PATH
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=IceBreaker2451
export KBUILD_BUILD_USER="liquid-CI"
status="BETA"

# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="%0ABuild started on <code>liquidCI</code>%0Adevice: <b>Redmi Note 6 Pro</b>%0Abranch: <code>$(git rev-parse --abbrev-ref HEAD)</code> (master)%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0ABuild Status: <code>${status}</code> %0AStarted by: <code>${KBUILD_BUILD_HOST}</code>"
}
# Push kernel to channel
function push() {
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="Build finished For <b>Redmi note 6 Pro</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage"
        -d chat_id="${chat_id}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
}
# Compile plox
function compile() {

    make O=out ARCH=arm64 tulip_defconfig
    make -j$(nproc --all) O=out \
                      LLVM=1 \
                      PATH=$KERNEL_DIR/clang/bin:$PATH \
                      ARCH=arm64 \
                      CC=clang \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      STRIP=llvm-strip \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      OBJSIZE=llvm-size \
                      HOSTCC=clang \
                      HOSTCXX=clang++ \
                      HOSTAR=llvm-ar \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \

    if ! [ -a "$IMAGE" ]; then
        finerr
    elsea
        push
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel
    zip -r9 liquid-1.4-tulip-${TANGGAL}.zip *
    cd ..
}

# Push kernel to channel
function kpush() {
    cd AnyKernel
    ZIP=$(echo *.zip)
        curl -F document=@$ZIP "https://api.telegram.org/bot${token}/sendDocument" \
        -F chat_id="${chat_id}" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build For <b>Redmi Note 6 Pro</b>"
}

sendinfo
compile
zipping
kpush
END=$(date +"%s")
DIFF=$(($END - $START))
push