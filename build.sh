#!/bin/bash

# in case build is executed from outside current dir be a gem and change the dir
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
cd $CURRENT_DIR

if [ ! -f /.dockerenv ]; then
  echo "ERROR: This script is only supported running in docker"
  exit 1
fi

if [ -d build ]; then
    rm -rf build/
fi
mkdir -p build
cd build

export TOOL=/opt/toolchains/mips-gcc720-glibc229
export CROSS=mips-linux-gnu-
export SYSROOT=/opt/k1-sysroot
export PREFIX=/usr

export CC="${TOOL}/bin/${CROSS}gcc --sysroot=${SYSROOT}"
export CXX="${TOOL}/bin/${CROSS}g++ --sysroot=${SYSROOT}"
export AR="${TOOL}/bin/${CROSS}ar"
export RANLIB="${TOOL}/bin/${CROSS}ranlib"
export STRIP="${TOOL}/bin/${CROSS}strip"

export CFLAGS="-Os -pipe -EL -march=mips32r2 -mhard-float -mfp64 -mnan=2008 -mno-mips16 -mno-micromips -fno-strict-aliasing"
export LDFLAGS="-Wl,-EL -Wl,-m,elf32ltsmip -Wl,--gc-sections \
  -Wl,-rpath-link,${SYSROOT}/lib -Wl,-rpath-link,${SYSROOT}${PREFIX}/lib \
  -Wl,--dynamic-linker=/lib/ld-linux-mipsn8.so.1"

tar -zxf ../openssh-9.8p1.tar.gz
cd openssh-9.8p1

./configure \
  --host="${CROSS%-}" \
  --build="$(gcc -dumpmachine)" \
  --prefix="${PREFIX}" \
  --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx \
  --without-openssl --without-libedit --without-zlib

make -j"$(nproc)" sftp-server
${STRIP} sftp-server
tar -zcf $CURRENT_DIR/build/sftp-server.tar.gz sftp-server

