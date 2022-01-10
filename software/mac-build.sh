#!/bin/sh

BUILD_ARCH=""
NOBUILD=""
BUILD_UNIV=0
BUILD_OP="all"
INSTALL_DIR="/usr/local/bin"

if test $# -ne 0 ; then
	### Options
	while test $# -gt 0;
	do
		### Get the option flag and switch on that basis
		case "$1" in
			-h) 
				### Usage information
				echo "Usage: ./build.sh -h"
				echo "       ./build.sh [[-a]|[-o]] [-i <ALT_INSTALL_DIR] [-o BUILD_OPERATION]"
				echo ""
				echo "Options:"
				echo "    -h        Print this usage summary."
				echo "    -a <arch> Build for i386|x86_64|arm64 architecture only."
				echo "              No point in trying ppc - wxWidgets requires"
				echo "              10.7 and the last SDK to support ppc was 10.6"
				echo "              Overrides -n if follows on command line."
				echo "              Disables universal build."
				echo "    -i        Overide the default (/usr/local/bin) install directory for the"
				echo "              'install' build operation."
				echo "    -n        Build only the native architecture."
				echo "              Overrides -a if follows on command line."
				echo "              Disables universal build."
				echo "    -o <op>   Do the specified build script operation. Options are:"
				echo "                  all -       Default. Build all the scsi2sd tools and package"
				echo "                              them."
				echo "                  clean -     remove tool executables and objects from the"
				echo "                              build tree. Respects the -a option."
				echo "                  treeclean - remove entire build tree."
				echo "                  distclean - remove entire build tree and distribution tree."
				echo "                  install -   install tools from distribution tree to local"
				echo "                              machine."
				echo ""
				NOBUILD=1
				break
			;;
			-a)
				### mac build - build only specified architecture
				shift
				echo "mac-build.sh - building for ${1} only. Disabling universal builds..."
				BUILD_ARCH="${1}"
				BUILD_UNIV=1
				shift
			;;
			-i)
				### mac build - overide default install dir (/usr/loca/bin)
				shift
				echo "mac-build.sh - will install to ${1}..."
				INSTALL_DIR="${1}"
				shift
			;;
			-n)
				### mac build - build only host architecture
				BUILD_ARCH=`uname -m`
				echo "mac-build.sh - building for native architecture ${BUILD_ARCH} only. Disabling universal builds..."
				BUILD_UNIV=1
				shift
			;;
			-o)
				### mac build - build script operation 
				shift
				echo "mac-build.sh - build operation: '$1'"
				BUILD_OP="${1}"
				shift
			;;
			-*) echo "Usage: ${1} not understood!"
				echo "Use ./build.sh -h for usage information"
				NOBUILD=1
				break
			;;
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

ARCH_FLAGS=""
for BUILD_ARCH in "${BUILD_ARCHS[@]}"; do
	ARCH_FLAGS="${ARCH_FLAGS} -arch ${BUILD_ARCH}"
done
# Trim leading space
ARCH_FLAGS=`echo "${ARCH_FLAGS}" | xargs`
cd scsi2sd-util
make ARCH="${ARCH_FLAGS}" -C ./
BUILD_RES=$?
cd ..

# bale out while testing new build system
exit 0

if [ "${BUILD_OP}" = 'all' -o "${BUILD_OP}" = 'install' ]; then
	### Start build
	echo "mac-build.sh - building for: ${BUILD_ARCHS[@]}"
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
	rm -rf ./build/mac-*
	
	### install if required
	if [ "${BUILD_OP}" = 'install' ]; then
		install -dv "${INSTALL_DIR}"
		install -v build/mac/scsi2sd-util/scsi2sd-util "${INSTALL_DIR}"
		install -v build/mac/scsi2sd-util/scsi2sd-monitor "${INSTALL_DIR}"
		install -v build/mac/scsi2sd-util/scsi2sd-bulk "${INSTALL_DIR}"
	fi
elif [ "${BUILD_OP}" = 'clean' ]; then
	### Clean executables
	echo "mac-build.sh - cleaning executables and objects for: ${BUILD_ARCHS[@]}"
	for BUILD_ARCH in "${BUILD_ARCHS[@]}"; do
		echo "mac-build.sh - cleaning ${BUILD_ARCH} executables and objects..."
		cd scsi2sd-util
		make ARCH="${BUILD_ARCH}" -C ./ clean
		cd ..
	done
elif [ "${BUILD_OP}" = 'treeclean' -o "${BUILD_OP}" = 'distclean' ]; then
	### Remove build tree
	echo "mac-build.sh - removing entire build tree..."
	for BUILD_ARCH in "${BUILD_ARCHS[@]}"; do
		echo "mac-build.sh - deleting ${BUILD_ARCH} build tree..."
		rm -rf ./scsi2sd-util/build/mac-"${BUILD_ARCH}"
	done
	if [ "${BUILD_OP}" = 'distclean' ]; then
		### Remove distribution tree
		echo "mac-build.sh - removing distribution tree..."
		rm -rf ./build
	fi
else
	echo "mac-build.sh - unrecognised build option '${BUILD_OP}'. Exiting..."
	exit 1
fi
