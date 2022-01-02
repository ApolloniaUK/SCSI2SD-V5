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
						echo "              No point in trying ppc - wxWidgets requires"
						echo "              10.7 and the last SDK to support ppc was 10.6"
						echo "              Disables universal build."
						echo "    -n        Build only the native architecture:"
						echo "              Disables universal build."
						echo ""
						NOBUILD=1
						break
					;;
					-n)
						### mac build - build only host architecture
						BUILD_ARCH=`uname -m`
						echo "mac-build.sh - building for native architecture ${BUILD_ARCH} only. Disabling universal builds..."
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

### Start build
for BUILD_ARCH in "${BUILD_ARCHS[@]}"; do
	echo "mac-build.sh - building ${BUILD_ARCH}"
	cd scsi2sd-util
	make ARCH="${BUILD_ARCH}" -C ./
	BUILD_RES=$?
	cd ..
	if [ $BUILD_RES -eq 0 ]; then
		mkdir -p build/mac-${BUILD_ARCH}
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-util build/mac-${BUILD_ARCH} && \
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-bulk build/mac-${BUILD_ARCH} && \
		cp scsi2sd-util/build/mac-${BUILD_ARCH}/scsi2sd-monitor build/mac-${BUILD_ARCH}
	else
		exit 1
	fi
done

### Create distro disk image
if [ ${#BUILD_ARCHS[@]} -gt 1 ] ; then
	echo "mac-build.sh - packaging Mac distro (universal for ${BUILD_ARCHS[@]})..."
else
	echo "mac-build.sh - packaging Mac distro (for ${BUILD_ARCHS[@]})..."
fi
rm -rf ./build/mac/scsi2sd-util*
mkdir -p ./build/mac/scsi2sd-util
lipo -create ./build/mac-*/scsi2sd-bulk -output ./build/mac/scsi2sd-util/scsi2sd-bulk
lipo -create ./build/mac-*/scsi2sd-monitor -output ./build/mac/scsi2sd-util/scsi2sd-monitor
lipo -create ./build/mac-*/scsi2sd-util -output ./build/mac/scsi2sd-util/scsi2sd-util
chmod a+rx ./build/mac/scsi2sd-util/*
hdiutil create -ov -fs HFS+ -srcfolder ./build/mac/scsi2sd-util ./build/mac/scsi2sd-util.dmg
rm -rf ./build/mac/scsi2sd-util ./build/mac-*
