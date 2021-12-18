#!/bin/sh

case `uname -s` in
Linux)
	# Builds all of the utilities (not firmware) under Linux.
	# Requires mingw installed to cross-compile Windows targets.

	(cd scsi2sd-util && ./build.sh)

	if [ $? -eq 0 ]; then
		mkdir -p build/linux
		mkdir -p build/windows/64bit
		mkdir -p build/windows/32bit

		cp scsi2sd-util/build/linux/scsi2sd-util build/linux

		cp scsi2sd-util/build/windows/32bit/scsi2sd-util.exe build/windows/32bit

		cp scsi2sd-util/build/windows/64bit/scsi2sd-util.exe build/windows/64bit
	fi
;;

Darwin)
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
							echo "    -a <arch> Build for i386|x86_64|arm64 architecture - i386 will fail on Lion."
							echo "              Disables universal build."
							echo "    -o        Build only the host architecture:"
							echo ""
							NOBUILD=true
							break
						;;
						-o)
							### mac build - build only host architecture
							BUILD_ARCH=`uname -m`
							echo "scsi2sd-util - building for host architecture (${BUILD_ARCH}) only. Disabling universal builds..."
							BUILD_UNIV=1
						;;
						-a)
							### mac build - build only specified architecture
							shift
							echo "scsi2sd-util - building for ${1} only. Disabling universal builds..."
							BUILD_ARCH="${1}"
							BUILD_UNIV=1
						;;
						-*) echo "Usage: "$1" not understood!"
							echo "Use ./build.sh -h for usage information"
							NOBUILD=true
							break
						;;
					esac
			esac
		done
	fi
	
	### Bale out if bad option or not called to build, just for info

	if test $NOBUILD ; then
		exit
	fi
	
	### Start build
	
	XCBVERS_RAW=`xcodebuild -version`
	XCBVERS_STR=$( echo $XCBVERS | cut -d ' ' -f 2)
	IFS='.' read -r -a XCVERS <<< $XCBVERS_STR
	### DEBUG_START
	echo $XCVERS
	### DEBUG_END
	
	cd scsi2sd-util
	# make -C ./
	env /usr/bin/arch -x86_64 make -C ./
	if [ $? -eq 0 ]; then
		cd ..
		ARCH=x86_64
		mkdir -p build/mac-${ARCH}

		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-util build/mac-${ARCH}
		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-bulk build/mac-${ARCH}
		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-monitor build/mac-${ARCH}
	else
		cd  ..
	fi
	
	cd scsi2sd-util
	# make -C ./
	env /usr/bin/arch -arm64 make -C ./
	if [ $? -eq 0 ]; then
		cd ..
		ARCH=arm64
		mkdir -p build/mac-${ARCH}

		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-util build/mac-${ARCH}
		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-bulk build/mac-${ARCH}
		cp scsi2sd-util/build/mac-${ARCH}/scsi2sd-monitor build/mac-${ARCH}
	else
		cd  ..
	fi
	
	mkdir build/mac
	lipo -create ./build/mac-*/scsi2sd-bulk -output ./build/mac/scsi2sd-bulk
	lipo -create ./build/mac-*/scsi2sd-monitor -output ./build/mac/scsi2sd-monitor
	lipo -create ./build/mac-*/scsi2sd-util -output ./build/mac/scsi2sd-util
	
esac
