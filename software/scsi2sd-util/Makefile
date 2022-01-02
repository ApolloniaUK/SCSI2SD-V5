VPATH=cybootloaderutils ../SCSI2SD/src

VERSION=4.4.0
NAME=scsi2sd-util

ifeq ($(USE_SYSTEM), Yes)
USE_SYSTEM_HIDAPI = Yes
USE_SYSTEM_ZLIB = Yes
USE_SYSTEM_WX = Yes
endif

ifeq ($(USE_SYSTEM_HIDAPI), Yes)
CPPFLAGS_HIDAPI=$(shell pkg-config hidapi-hidraw --cflags)
LDFLAGS_HIDAPI=$(shell pkg-config hidapi-hidraw --libs)
else
CPPFLAGS_HIDAPI=-I hidapi/hidapi
LDFLAGS_HIDAPI=
endif

ifeq ($(USE_SYSTEM_ZLIB), Yes)
CPPFLAGS_ZLIB=$(shell pkg-config zlib --cflags)
LDFLAGS_ZLIB=$(shell pkg-config zlib --libs)
LIBZIPPER_CONFIG = --disable-shared LDFLAGS="$(LDFLAGS_ZLIB)" CPPFLAGS="$(CPPFLAGS_ZLIB)"
else
CPPFLAGS_ZLIB=-I$(BUILD)/zlib
LDFLAGS_ZLIB=-L$(BUILD)/zlib -lz
LIBZIPPER_CONFIG = --disable-shared LDFLAGS="-L../zlib" CPPFLAGS="-I../zlib"
endif

ifeq ($(USE_SYSTEM_WX),Yes)
LDFLAGS_WX=$(shell wx-config-3.0 --libs)
else
LDFLAGS_WX=$(shell $(BUILD)/wx/wx-config --libs)
endif

CPPFLAGS = -I cybootloaderutils $(CPPFLAGS_HIDAPI) -I. -I ../include -Ilibzipper-1.0.4 $(CPPFLAGS_ZLIB)
CFLAGS += -Wall -Wno-pointer-sign -O2 -g
CXXFLAGS += -Wall -O2 -g -std=c++0x

LDFLAGS += -L$(BUILD)/libzipper/.libs -lzipper $(LDFLAGS_ZLIB) $(LDFLAGS_HIDAPI)


# wxWidgets 3.0.2 uses broken Webkit headers under OSX Yosemite
# liblzma not available on OSX 10.7
# --disable-mediactrl for missing Quicktime.h on Mac OSX Sierra
WX_CONFIG=--disable-webkit --disable-webviewwebkit  --disable-mediactrl \
	--without-libtiff --without-libjbig --without-liblzma --without-opengl \
	--enable-monolithic --enable-stl --disable-shared

TARGET ?= $(shell uname -s)
ifeq ($(TARGET),Win32)
	VPATH += hidapi/windows
	LDFLAGS += -static -mconsole -mwindows -lsetupapi
	BUILD := $(PWD)/build/windows/32bit
	CC=i686-w64-mingw32-gcc
	CXX=i686-w64-mingw32-g++
	LIBZIPPER_CONFIG+=--host=i686-w64-mingw32
	EXE=.exe
	WX_CONFIG+=--host=i686-w64-mingw32
	TARGETOBJ = $(BUILD)/gnulib_ffs.o
endif
ifeq ($(TARGET),Win64)
	VPATH += hidapi-windows
	LDFLAGS += -static -mconsole -mwindows -lsetupapi
	BUILD := $(PWD)/build/windows/64bit
	CC=x86_64-w64-mingw32-gcc
	CXX=x86_64-w64-mingw32-g++
	LIBZIPPER_CONFIG+=--host=x86_64-w64-mingw32
	EXE=.exe
	WX_CONFIG+=--host=x86_64-w64-mingw32
	TARGETOBJ = $(BUILD)/gnulib_ffs.o
endif
ifeq ($(TARGET),Linux)
	VPATH += hidapi/linux
	LDFLAGS += -ludev -lexpat
	BUILD := $(PWD)/build/linux
endif
ifneq ($(TARGET),Darwin)
	# NOOP()s for zlib and libzipper target patchers in non-OSX builds.
	# 
	# In Mac OS builds there are files in the build tree which need to be
	# patched between the 'configure' and 'make' phases for those targets. I do
	# this by using a variable to hold the whole patch command and adding a new
	# line to the multi-line conditionalised target build commands for those
	# targets, between the 'configure' and 'make' lines, whose only content is
	# that variable. If that variable is an empty string for non-Mac builds the
	# build fails because it is not a command and so does not return success or
	# failure and so the end of line '&&' test fails'.
	ZLIB_MAC_GZGUTS_PATCH = echo "zlib: non-Mac build, no need to patch gzguts.h."
	LIBZIPPER_MAKE_PATCH = echo "libzipper: non-Mac build, no need to patch Makefile."
endif
ifeq ($(TARGET),Darwin)
	# Should match OSX
	ifndef ARCH
	ARCH ?= $(shell uname -m)
	endif
	VPATH += hidapi-mac
	LDFLAGS += -framework IOKit -framework CoreFoundation -lexpat
	CC=clang -mmacosx-version-min=10.7
	CXX=clang++ -stdlib=libc++ -mmacosx-version-min=10.7
	WX_CONFIG += --with-macosx-version-min=10.7 --with-osx_cocoa
	CPPFLAGS_WXBUILD += -D__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES=1 -arch $(ARCH)
	ZLIB_MAC_CONFIG = --archs="-arch $(ARCH)"
	LDFLAGS_ZLIB += -arch $(ARCH)
	CFLAGS += -arch $(ARCH)
	CXXFLAGS += -arch $(ARCH)
	BUILD := $(PWD)/build/mac-$(ARCH)
	# OSX patch for zlib
	#
	# When building zlib for arm64 on OSX the build fails because zlib.h is not
	# included by gzguts.h. The variable defined on the first line after this
	# comment holds a sed command that patches gzguts.h in the build tree
	# keeping ths distribution tree clean. The (to most people) slightly odd
	# formulation of the sed command is because OSX sed is BSD based and
	# expects it's command components on separate lines. The solution to this
	# problem was adapted from a Stack Overflow answer:
	# <https://stackoverflow.com/a/57392014>
		ZLIB_MAC_GZGUTS_PATCH = echo "zlib: Mac build, patching gzguts.h." ; sed -i '' '21a\'$$'\n''\#include "zlib.h"'$$'\n' $(BUILD)/zlib/gzguts.h
	# OSX patch for libzipper.
	# 
	# When building libzipper the only way to get the build architecture flag to
	# the C++ compiler is to pass#= it to 'make' on the command line by setting
	# it as the contents of the variable CXXFLAGS. Unfortunately this suppresses
	# any CXXFLAGS configure has generated within the Makefile. The variable
	# defined on the first line after this comment holds a sed command that
	# patches the generated makefile so the configure-generated CXXFLAGS are
	# appended to my overriding command line CXXGLAGS. The next line defines a
	# variable used to pass the architecture flags in CXXFLAGS to the make
	# command.
		LIBZIPPER_MAKE_PATCH = echo "libzipper:  Mac build, patching libzipper Makefile." ; sed -i '.orig' -e 's/CXXFLAGS \= /override CXXFLAGS += /' $(BUILD)/libzipper/Makefile
		LIBZIPPER_CXXFLAGS_MAC = "CXXFLAGS=-arch $(ARCH)"
endif

export CC CXX

all:  $(BUILD)/scsi2sd-util$(EXE) $(BUILD)/scsi2sd-monitor$(EXE) $(BUILD)/scsi2sd-bulk$(EXE)

CYAPI = \
	$(BUILD)/cybtldr_api2.o \
	$(BUILD)/cybtldr_api.o \
	$(BUILD)/cybtldr_command.o \
	$(BUILD)/cybtldr_parse.o \


ifneq ($(USE_SYSTEM_HIDAPI),Yes)
HIDAPI = \
	$(BUILD)/hid.o
endif


CONSOLEOBJ = \
	$(CYAPI) $(HIDAPI) \
	$(BUILD)/Firmware.o \
	$(BUILD)/SCSI2SD_Bootloader.o \
	$(BUILD)/SCSI2SD_HID.o \
	$(BUILD)/hidpacket.o \
	$(TARGETOBJ)

OBJ = \
	${CONSOLEOBJ} \
	$(BUILD)/ConfigUtil.o \
	$(BUILD)/BoardPanel.o \
	$(BUILD)/TargetPanel.o \
	$(BUILD)/hidpacket.o \

EXEOBJ = \
	$(BUILD)/scsi2sd-util.o \
	$(BUILD)/scsi2sd-monitor.o \



ifneq ($(USE_SYSTEM_ZLIB),Yes)
$(OBJ): $(BUILD)/zlib/buildstamp
$(EXEOBJ): $(BUILD)/zlib/buildstamp
$(BUILD)/zlib/buildstamp:
	mkdir -p $(dir $@)
	( \
		cd $(dir $@) && \
		cp -a $(CURDIR)/zlib-1.2.8/* . && \
		./configure --static $(ZLIB_MAC_CONFIG) && \
		$(ZLIB_MAC_GZGUTS_PATCH) && \
		$(MAKE) \
	) && \
	touch $@
endif

ifneq ($(USE_SYSTEM_WX),Yes)
$(OBJ): $(BUILD)/wx/buildstamp
$(EXEOBJ): $(BUILD)/wx/buildstamp
ifneq ($(USE_SYSTEM_ZLIB),Yes)
$(BUILD)/wx/buildstamp: $(BUILD)/zlib/buildstamp
else
$(BUILD)/wx/buildstamp:
endif
	mkdir -p $(dir $@)
	( \
		cd $(dir $@) && \
		$(CURDIR)/wxWidgets/configure $(WX_CONFIG) CPPFLAGS="$(CPPFLAGS_ZLIB) $(CPPFLAGS_WXBUILD)" LDFLAGS="$(LDFLAGS_ZLIB)" && \
		$(MAKE) \
	) && \
	touch $@
endif

ifneq ($(USE_SYSTEM_ZLIB),Yes)
LIBZIPPER_STATIC=-enable-static
endif

$(OBJ): $(BUILD)/libzipper/buildstamp
$(EXEOBJ): $(BUILD)/libzipper/buildstamp
ifneq ($(USE_SYSTEM_ZLIB),Yes)
$(BUILD)/libzipper/buildstamp: $(BUILD)/zlib/buildstamp
else
$(BUILD)/libzipper/buildstamp:
endif
	mkdir -p $(dir $@)
	( \
		cd $(dir $@) && \
		$(CURDIR)/libzipper-1.0.4/configure ${LIBZIPPER_CONFIG} --disable-shared $(LIBZIPPER_STATIC) && \
		$(LIBZIPPER_MAKE_PATCH) && \
		$(MAKE) $(LIBZIPPER_CXXFLAGS_MAC) libzipper.la \
	) && \
	touch $@

$(BUILD)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $< -c -o $@

$(BUILD)/%.o: %.cc
	mkdir -p $(dir $@)
ifneq ($(USE_SYSTEM_WX),Yes)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) `$(BUILD)/wx/wx-config --cxxflags` $< -c -o $@
else
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) `wx-config-3.0 --cxxflags` $< -c -o $@
endif

$(BUILD)/scsi2sd-util$(EXE): $(OBJ) $(BUILD)/scsi2sd-util.o
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $^ $(LDFLAGS_WX) $(LDFLAGS) -o $@

$(BUILD)/scsi2sd-monitor$(EXE): $(OBJ) $(BUILD)/scsi2sd-monitor.o
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $^ $(LDFLAGS_WX) $(LDFLAGS) -o $@

$(BUILD)/scsi2sd-bulk$(EXE): $(CONSOLEOBJ) $(BUILD)/scsi2sd-bulk.o
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@

clean:
	rm $(BUILD)/scsi2sd-util$(EXE) $(OBJ) $(BUILD)/libzipper/buildstamp

PREFIX=/usr
install:
	install -d $(DESTDIR)/$(PREFIX)/bin
	install build/linux/scsi2sd-util $(DESTDIR)/$(PREFIX)/bin
	install build/linux/scsi2sd-monitor $(DESTDIR)/$(PREFIX)/bin

dist:
	rm -fr $(NAME)-$(VERSION)
	mkdir $(NAME)-$(VERSION)
	cp -pr build.sh ConfigUtil.cc ConfigUtil.hh scsi2sd-util.spec \
               ../SCSI2SD/src/hidpacket.c ../include/hidpacket.h ../include/scsi2sd.h \
	       cybootloaderutils Firmware.cc Firmware.hh libzipper-1.0.4 Makefile \
               SCSI2SD_Bootloader.cc SCSI2SD_Bootloader.hh SCSI2SD_HID.cc SCSI2SD_HID.hh \
	       scsi2sd-monitor.cc scsi2sd-util.cc TargetPanel.cc TargetPanel.hh \
	       BoardPanel.cc BoardPanel.hh \
	       $(NAME)-$(VERSION)
	tar jcvf $(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)
