#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
OBJDUMP="${OBJDUMP:-objdump}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$testname
mkdir -p $t

[ $MACHINE = x86_64 ] || { echo skipped; exit; }

cat <<EOF | $CC -o $t/a.o -c -x assembler -
.globl main
main:
  call _exit@PLT
EOF

$CC -B. -o $t/exe $t/a.o
readelf --notes $t/exe > $t/log
! grep -qw SHSTK $t/log

$CC -B. -o $t/exe $t/a.o -Wl,-z,ibt
readelf --notes $t/exe | grep -qw IBT

echo OK
