#!/bin/bash
###########################
#  a kernel build script
#  please move to kernel root directory
###########################

##
#  some color setting
##
cinfo="\x1b[38;2;79;155;250m"
cwarn="\x1b[38;2;255;200;97m"
cerror="\x1b[38;2;240;96;96m"
cno="\x1b[0"


echo -e "${cinfo}=============== Setup Some Export ===============${cno}"
# kernel workdir
export KERNEL_DIR=$(pwd)
# kernel build defconfig
export KERNEL_DEFCONFIG=vendor/alioth_defconfig
# build tmp dir
export OUT=out
# anykernel3 workdir
export ANYKERNEL3=${KERNEL_DIR}/AnyKernel3
# kernel zip name
export KERNEL_ZIP_NAME="N0_Alioth-KSU_v1.0.0.zip"
# kernel move to dir
export KERNEL_ZIP_EXPORT="/root/"
# clang path
export CLANG_PATH=/root/toolchains/zyc-clang-17
export PATH=${CLANG_PATH}/bin:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
# aarch
export ARCH=arm64
export SUBARCH=arm64

# build thread count
TH_COUNT=1
if [[ "" != "$1" ]]; then
	TH_NUM=$1
fi

export DEF_ARGS="O=${OUT} \
				CC=clang \
				CXX=clang++ \
				ARCH=${ARCH} \
				CROSS_COMPILE=${CLANG_PATH}/bin/aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=${CLANG_PATH}/bin/arm-linux-gnueabi- \
				LD=ld.lld "
export BUILD_ARGS="-j${TH_COUNT} ${DEF_ARGS}"

echo -e "${cwarn}kernel workspace dir is => ${KERNEL_DIR}"
echo -e "kernel build defonfig is => ${KERNEL_DEFCONFIG}"
echo -e "build tmpdir is => ${KERNEL_DIR}/${OUT}"
echo -e "anykernel3 workspace dir is => ${ANYKERNEL3}"
echo -e "kernel zip name is => ${KERNEL_ZIP_NAME}"
echo -e "kernel zip export dir is => ${KERNEL_ZIP_EXPORT}"
echo -e "clang path is => ${CLANG_PATH}"
echo -e "build arch/subarch is => ${ARCH} / ${SUBARCH}${cno}"

echo -e "${cinfo}=============== Make defconfig ===============${cno}"
make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
if [[ "0" != "$?" ]]; then
	echo -e "${cerror}>>> make defconfig error, build stop!${cno}"
	exit 1
fi
echo -e "${cinfo}=============== Make Kernel  ===============${cno}"
make ${BUILD_ARGS}
if [[ "0" != "$?" ]]; then
	echo -e "${cerror}>>> build kernel error, build stop!${cno}"
	exit 1
fi
echo -e "${cwarn}>>> build kernel success${cno}"
echo -e "${cinfo}=============== Make Kernel Zip ==============="
if test -e ${ANYKERNEL3}; then
	if test -e ${KERNEL_DIR}/${OUT}/arch/${ARCH}/boot/dtbo.img; then
		if test -e ${KERNEL_DIR}/${OUT}/arch/${ARCH}/boot/Image.gz-dtb; then
			echo -e "${cwarn}move kernel files . . .${cno}"
			mv ${KERNEL_DIR}/${OUT}/arch/${ARCH}/boot/dtbo.img ${ANYKERNEL3}/
			mv ${KERNEL_DIR}/${OUT}/arch/${ARCH}/boot/Image.gz-dtb ${ANYKERNEL3}/
			echo -e "${cwarn}into anykernel3 workdir. . ."
			cd ${ANYKERNEL3}
			if test -e ./Image.gz-dtb; then
				zip -r ${KERNEL_ZIP_NAME} ./*
				test -e ./${KERNEL_ZIP_NAME} && mv ./${KERNEL_ZIP_NAME} ${KERNEL_ZIP_EXPORT}
				echo -e "${cwarn} clean kernel files. . .${cno}"
				test -e ./Image.gz-dtb && rm ./Image.gz-dtb
				test -e ./dtbo.img && rm ./dtbo.img
			else
				echo -e "${cerror}stopmake => kernel file not found!${cno}"
				exit 1
			fi
		else
			echo -e "${cerror}stop make => Image.gz-dtb not found${cno}"
			exit 1
		fi
	else
		echo -e "${cerror}stop make => dtbo.img not found${cno}"
		exit 1
	fi
else
	echo -e "${cerror}stop build => anykernel3 dir not found${cno}"
	exit 1
fi
exit 0
