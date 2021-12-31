#!/bin/sh

BUILD_ARCH=""
NOBUILD=""
BUILD_UNIV=0

if test $# -ne 0 ; then
	### Options
	while test $# -gt 0;
	do
		### Get the option flag and switch on that basis
		case "$1" in
			-*) FLAG="$1" 
				case "$FLAG" in
					-h) 
						### Usage information
						echo "Usage: ./build.sh -h"
						echo "       ./build.sh [[-a]|[-o]]"
						echo ""
						echo "Options:"
						echo "    -h        Print this usage summary."
						echo "    -a <arch> Build for i386|x86_64|arm64 architecture only."
						echo "              Disables universal build."
						echo "    -o        Build only the host architecture:"
						echo ""
						NOBUILD=0
						break
					;;
					-o)
						### mac build - build only host architecture
						BUILD_ARCH=`uname -m`
						echo "mac-build.sh - building for host architecture ${BUILD_ARCH} only. Disabling universal builds..."
						BUILD_UNIV=1
						break
					;;
					-a)
						### mac build - build only specified architecture
						shift
						echo "mac-build.sh - building for ${1} only. Disabling universal builds..."
						BUILD_ARCH="${1}"
						BUILD_UNIV=1
						break
					;;
					-*) echo "Usage: ${1} not understood!"
						echo "Use ./build.sh -h for usage information"
						NOBUILD=1
						break
					;;
				esac
		esac
	done
fi

### Bale out if bad option or not called to build, just for info

if test $NOBUILD ; then
	exit $NOBUILD
fi

### Which architecture(s) are we building?
declare -a BUILD_ARCHS
if [ "${BUILD_ARCH}" != "" ]; then
	cc test.c -arch ${BUILD_ARCH} -o test > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		BUILD_ARCHS=("${BUILD_ARCH}")
	else
		echo "mac-build.sh - ${BUILD_ARCH} not supported on this host. Exiting..."
		exit 1
	fi	
	BUILD_ARCHS=("${BUILD_ARCH}")
else
	echo "mac-build.sh - testing which architectures are buildable..."
	ALL_ARCHS=("ppc" "ppc64" "i386" "x86_64" "arm64")
	TMP_DIR=`mktemp -d`
	cd "${TMP_DIR}"
	echo "int main(void) {return(0);}" > test.c
	for ARCH in "${ALL_ARCHS[@]}"; do
		cc test.c -arch ${ARCH} -o test > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			BUILD_ARCHS=("${BUILD_ARCHS[@]}" "${ARCH}")
		fi
	done
	cd - > /dev/null
	rm -rf "${TMP_DIR}"
fi
echo "mac-build.sh - building for: ${BUILD_ARCHS[@]}"

if [ 1 -eq 0 ] ; then
	XCBVERS_RAW=`xcodebuild -version`
	XCBVERS_STR=$( echo $XCBVERS | cut -d ' ' -f 2)
	IFS='.' read -r -a XCVERS <<< $XCBVERS_STR
	### DEBUG_START
	echo $XCVERS
	### DEBUG_END
fi

# ppc not supported in 10.7 SDK so no need to even try building
# Xcode 10 will not build i386
# Xcode 12.2 required for arm64
# looks like test build of c file is required to really test
#
# echo "int main(void) {return(0);}" > test.c
# cc -arch arm64 test.c -o test > /dev/null 2>&1
#		returns 1 in $? if can't build for specified architecture
# 
# will need to test in scsi2sd-util/Makefile for arm64 build 
# (with uname -m) and patch the copied scsi2sd-util/wxWidgets/configure, 
# scsi2sd-util/wxWidgets/src/zlib/gzguts.h and possibly 
# scsi2sd-util/wxWidgets/configure.in

### Start build
for BUILD_ARCH in "${BUILD_ARCHS[@]}"; do
	echo "mac-build.sh - building ${BUILD_ARCH}"
	cd scsi2sd-util
	# env /usr/bin/arch "-${BUILD_ARCH}" make -C ./
	make ARCH="${BUILD_ARCH}" -C ./
	if [ $? -eq 0 ]; then
		cd ..
		mkdir -p build/mac-${BUILD_ARCH}
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-util build/mac-${BUILD_ARCH}
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-bulk build/mac-${BUILD_ARCH}
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-monitor build/mac-${BUILD_ARCH}
	else
		cd  ..
	fi
done

### Create universal binaries
mkdir build/mac
lipo -create ./build/mac-*/scsi2sd-bulk -output ./build/mac/scsi2sd-bulk
lipo -create ./build/mac-*/scsi2sd-monitor -output ./build/mac/scsi2sd-monitor
lipo -create ./build/mac-*/scsi2sd-util -output ./build/mac/scsi2sd-util
