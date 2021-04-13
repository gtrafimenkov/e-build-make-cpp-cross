# Copyright (c) 2021 Gennady Trafimenkov
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.


ifneq "$(shell uname)" "Linux"
  $(error This build script must run on Linux)
endif

# By default building binary for whatever system the build system is running
TARGET_ARCH    ?=

# Place for object and binary files
RELEASE_DIR    := build
ifeq "$(TARGET_ARCH)" ""
BUILD_DIR      := build/default
else
BUILD_DIR      := build/$(TARGET_ARCH)
endif

# Content of lib1 is built into a static library.
# Explanation for following commands:
#   - `shell find` finds list of source files
#   - `filter` replaces extension to .o for all of them
#   - `addprefix` is used to prepend every path with build dir location
#   - `$(OBJS:.o=.d)` replaces list extension .o to .d; .d files will be built by
#     the compiler (see option -MDD) and contain list of dependencies for corresponding
#     .o files.  Later this list of dependencies in included into this make file
#     using instruction `-include $(DEPS)`
LIB1_BINARY  := $(BUILD_DIR)/lib1.a
LIB1_SOURCES := $(shell find lib1 -name '*.cc')
LIB1_OBJS0   := $(filter %.o, $(LIB1_SOURCES:.c=.o) $(LIB1_SOURCES:.cc=.o) $(LIB1_SOURCES:.cpp=.o))
LIB1_OBJS    := $(addprefix $(BUILD_DIR)/,$(LIB1_OBJS0))
LIB1_DEPS    := $(OBJS:.o=.d)

# The main binary will be built from content of src folder plus the static library
ifeq "$(TARGET_ARCH)" ""
MAIN_BINARY  := greeter
else
MAIN_BINARY  := greeter-$(TARGET_ARCH)
endif
MAIN_SOURCES := $(shell find src -name '*.cc')
MAIN_OBJS0   := $(filter %.o, $(MAIN_SOURCES:.c=.o) $(MAIN_SOURCES:.cc=.o) $(MAIN_SOURCES:.cpp=.o))
MAIN_OBJS    := $(addprefix $(BUILD_DIR)/,$(MAIN_OBJS0))
MAIN_DEPS    := $(OBJS:.o=.d)

ifeq "$(TARGET_ARCH)" "linux-gcc-amd64"
	AR             := ar
	CC             := gcc
	CXX            := g++
	CFLAGS         += -m64
endif

ifeq "$(TARGET_ARCH)" "linux-gcc-x86"
	AR             := ar
	CC             := gcc
	CXX            := g++
	CFLAGS         += -m32
endif

ifeq "$(TARGET_ARCH)" "linux-clang-amd64"
	AR             := ar
	CC             := clang
	CXX            := clang++
	CFLAGS         += -m64
endif

ifeq "$(TARGET_ARCH)" "linux-clang-x86"
	AR             := ar
	CC             := clang
	CXX            := clang++
	CFLAGS         += -m32
endif

ifeq "$(TARGET_ARCH)" "win32"
	AR             := i686-w64-mingw32-ar
	CC             := i686-w64-mingw32-gcc
	CXX            := i686-w64-mingw32-g++
endif

ifeq "$(TARGET_ARCH)" "win64"
	AR             := x86_64-w64-mingw32-ar
	CC             := x86_64-w64-mingw32-gcc
	CXX            := x86_64-w64-mingw32-g++
endif

CFLAGS += -g
CFLAGS += -I .
CFLAGS += -Wall

CFLAGS_C   := $(CFLAGS) -std=c17
CFLAGS_CXX := $(CFLAGS) -std=c++17

# Building static binaries
LDFLAGS += -static

SRCS := $(MAIN_SOURCES) $(LIB1_SOURCES)
DEPS := $(MAIN_DEPS)    $(LIB1_DEPS)

$(RELEASE_DIR)/$(MAIN_BINARY): $(MAIN_OBJS) $(LIB1_BINARY)
	@echo '===> CXX $@'
	@mkdir -p $(RELEASE_DIR)
	@$(CXX) $(CFLAGS_CXX) $(LDFLAGS) $^ -o $@

all:
	$(MAKE) TARGET_ARCH=linux-gcc-amd64
	$(MAKE) TARGET_ARCH=linux-gcc-x86
	$(MAKE) TARGET_ARCH=linux-clang-amd64
	$(MAKE) TARGET_ARCH=linux-clang-x86
	$(MAKE) TARGET_ARCH=win32
	$(MAKE) TARGET_ARCH=win64

$(LIB1_BINARY): $(LIB1_OBJS)
	@echo '===> AR  $@'
	@$(AR) rcs $(LIB1_BINARY) $(LIB1_OBJS)

-include $(DEPS)

$(BUILD_DIR)/%.o: %.cc
	@echo '===> CXX $<'
	@mkdir -p $$(dirname $@)
	@$(CXX) $(CFLAGS_CXX) -c -MMD -o $@ $<

clean:
	rm -rf build

install-build-dependencies:
	sudo apt-get install -y \
		build-essential \
		clang \
		gcc-multilib \
		g++-multilib \
		gcc-mingw-w64 gcc-mingw-w64-i686 \
		g++-mingw-w64 g++-mingw-w64-i686
