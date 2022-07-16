VERSION = 1.3.1

PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib
LIBEXECDIR = $(PREFIX)/libexec
MANDIR = $(PREFIX)/share/man

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

OS := $(shell uname -s)
ARCH := $(shell uname -m)

  TESTS := $(wildcard test/elf/*.sh)

D = $(DESTDIR)

# CXX defaults to `g++`. Rewrite it with a vendor-neutral compiler
# name `c++`.
ifeq ($(origin CXX), default)
  CXX = c++
endif

# If you want to keep symbols in the installed binary, run make with
# `STRIP=true` to run /bin/true instead of the strip command.
STRIP = strip

SRCS = $(wildcard *.cc elf/*.cc)
OBJS = $(SRCS:%.cc=out/%.o) out/rust-demangle.o

IS_ANDROID = 0

# If you want to compile mold for debugging, invoke make as
# `make CXXFLAGS=-g`.
CFLAGS = -O2
CXXFLAGS = -O2

MOLD_CXXFLAGS := -std=c++20 -fno-exceptions -fno-unwind-tables \
                 -fno-asynchronous-unwind-tables -Ithird-party \
                 -DMOLD_VERSION=\"$(VERSION)\" -DLIBDIR="\"$(LIBDIR)\""

MOLD_LDFLAGS := -pthread -lz -lm -ldl

# Get a hash of the current git head. We don't want to use the git
# command because the command prints out a warning if running under
# sudo.
GIT_HASH := $(shell [ -f .git/HEAD ] && if grep -q '^ref:' .git/HEAD; then cat .git/`sed 's/^ref: //' .git/HEAD`; else cat .git/HEAD; fi)

ifneq ($(GIT_HASH),)
  MOLD_CXXFLAGS += -DGIT_HASH=\"$(GIT_HASH)\"
endif

LTO = 0
ifeq ($(LTO), 1)
  CXXFLAGS += -flto -O3
  LDFLAGS  += -flto
endif

# By default, we want to use mimalloc as a memory allocator. mimalloc
# is disabled on macOS and Android because it didn't work on those hosts.
USE_MIMALLOC = 1

ifeq ($(USE_MIMALLOC), 1)
  ifdef SYSTEM_MIMALLOC
    MOLD_CXXFLAGS += -DUSE_SYSTEM_MIMALLOC
    MOLD_LDFLAGS += -lmimalloc
  else
    MIMALLOC_LIB = out/mimalloc/libmimalloc.a
    MOLD_CXXFLAGS += -Ithird-party/mimalloc/include
    MOLD_LDFLAGS += -Wl,-whole-archive $(MIMALLOC_LIB) -Wl,-no-whole-archive
  endif
endif

ifdef SYSTEM_TBB
  MOLD_LDFLAGS += -ltbb
else
  TBB_LIB = out/tbb/libs/libtbb.a
  MOLD_LDFLAGS += $(TBB_LIB)
  MOLD_CXXFLAGS += -Ithird-party/tbb/include
endif

ifeq ($(OS), Linux)
  ifeq ($(IS_ANDROID), 0)
    # glibc before 2.17 need librt for clock_gettime
    MOLD_LDFLAGS += -Wl,-push-state -Wl,-as-needed -lrt -Wl,-pop-state
  endif
endif

NEEDS_LIBCRYPTO = 1
ifeq ($(OS), Darwin)
  NEEDS_LIBCRYPTO = 0
endif

ifeq ($(NEEDS_LIBCRYPTO), 1)
  MOLD_LDFLAGS += -lcrypto
endif

# '-latomic' flag is needed building on armv6/riscv64 systems.
# Seems like '-atomic' would be better but not working.
ifneq (,$(filter armv6% riscv64, $(ARCH)))
  MOLD_LDFLAGS += -latomic
endif


ifeq ($(OS), Linux)
  MOLD_WRAPPER_LDFLAGS = -Wl,-push-state -Wl,-no-as-needed -ldl -Wl,-pop-state
endif

DEPFLAGS = -MT $@ -MMD -MP -MF out/$*.d

all: mold mold-wrapper.so

-include $(SRCS:%.cc=out/%.d)

mold: $(OBJS) $(MIMALLOC_LIB) $(TBB_LIB)
	$(CXX) $(OBJS) -o $@ $(MOLD_LDFLAGS) $(LDFLAGS)
	ln -sf mold ld
	ln -sf mold ld64

mold-wrapper.so: elf/mold-wrapper.c
	$(CC) $(DEPFLAGS) $(CFLAGS) -fPIC -shared -o $@ $< $(MOLD_WRAPPER_LDFLAGS) $(LDFLAGS)

out/rust-demangle.o: third-party/rust-demangle/rust-demangle.c
	$(CC) $(CFLAGS) -c -o $@ $<

out/%.o: %.cc out/elf/.keep 
	$(CXX) $(MOLD_CXXFLAGS) $(DEPFLAGS) $(CXXFLAGS) -c -o $@ $<

out/elf/.keep:
	mkdir -p $(@D)
	touch $@

$(MIMALLOC_LIB):
	mkdir -p out/mimalloc
	(cd out/mimalloc; CFLAGS=-DMI_USE_ENVIRON=0 cmake -G'Unix Makefiles' ../../third-party/mimalloc)
	$(MAKE) -C out/mimalloc mimalloc-static

$(TBB_LIB):
	mkdir -p out/tbb
	(cd out/tbb; cmake -G'Unix Makefiles' -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF -DTBB_TEST=OFF -DCMAKE_CXX_FLAGS="$(CXXFLAGS) -D__TBB_DYNAMIC_LOAD_ENABLED=0" -DTBB_STRICT=OFF ../../third-party/tbb)
	$(MAKE) -C out/tbb tbb
	(cd out/tbb; ln -sf *_relwithdebinfo libs)

test tests check: all
	@$(MAKE) $(TESTS) --no-print-directory --output-sync

	@if test -t 1; then \
	  printf '\e[32mPassed all tests\e[0m\n'; \
	else \
	  echo 'Passed all tests'; \
	fi

test-arch:
	TEST_CC=${TRIPLE}-gcc \
	TEST_CXX=${TRIPLE}-g++ \
	TEST_GCC=${TRIPLE}-gcc \
	TEST_GXX=${TRIPLE}-g++ \
	OBJDUMP=${TRIPLE}-objdump \
	MACHINE=${MACHINE} \
	QEMU="qemu-${MACHINE} -L /usr/${TRIPLE}" \
	$(MAKE) test

test-all: all
	$(MAKE) test-arch TRIPLE=x86_64-linux-gnu MACHINE=x86_64
	$(MAKE) test-arch TRIPLE=i686-linux-gnu MACHINE=i386
	$(MAKE) test-arch TRIPLE=aarch64-linux-gnu MACHINE=aarch64
	$(MAKE) test-arch TRIPLE=arm-linux-gnueabihf MACHINE=arm
	$(MAKE) test-arch TRIPLE=riscv64-linux-gnu MACHINE=riscv64

# macOS's GNU make hasn't been updated since 3.8.1 perhaps due a concern
# of GPLv3. The --output-sync flag was introduced in GNU Make 4.0, so we
# can't use that flag on macOS.
#
# `tail -r | tail -r` is a poor-man's way to enable full buffering on a
# command output. `tail -r` outputs an input from the last line to the
# first.
$(TESTS):
	@./$@

install: all
	$(INSTALL) -d $D$(BINDIR)
	$(INSTALL_PROGRAM) mold $D$(BINDIR)
	$(STRIP) $D$(BINDIR)/mold

	$(INSTALL) -d $D$(LIBDIR)/mold
	$(INSTALL_DATA) mold-wrapper.so $D$(LIBDIR)/mold
	$(STRIP) $D$(LIBDIR)/mold/mold-wrapper.so

	$(INSTALL) -d $D$(LIBEXECDIR)/mold

# We want to make a symblink with a relative path, so that users can
# move the entire directory to other place without breaking the reference.
# GNU ln supports `--relative` to do that, but that's not supported by
# non-GNU systems. So we use Python to compute a relative path.
	ln -sf `python3 -c "import os.path; print(os.path.relpath('$(BINDIR)/mold', '$(LIBEXECDIR)/mold'))"` $D$(LIBEXECDIR)/mold/ld

	$(INSTALL) -d $D$(MANDIR)/man1
	$(INSTALL_DATA) docs/mold.1 $D$(MANDIR)/man1

uninstall:
	rm -f $D$(BINDIR)/mold $D$(BINDIR)/ld.mold $D$(BINDIR)/ld64.mold
	rm -f $D$(MANDIR)/man1/mold.1
	rm -rf $D$(LIBDIR)/mold

test-asan test-ubsan:
	$(MAKE) USE_MIMALLOC=0 CXXFLAGS='-fsanitize=address -fsanitize=undefined -O0 -g' LDFLAGS='-fsanitize=address -fsanitize=undefined' test

test-tsan:
	$(MAKE) USE_MIMALLOC=0 CXXFLAGS='-fsanitize=thread -O0 -g' LDFLAGS=-fsanitize=thread test

clean:
	rm -rf *~ mold mold-wrapper.so out ld ld64 mold-*-linux.tar.gz

.PHONY: all test tests check clean test-arch test-all test-asan test-ubsan test-tsan $(TESTS)
