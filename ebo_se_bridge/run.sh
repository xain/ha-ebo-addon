#!/usr/bin/env bash
# EBO SE add-on entrypoint.
# 1) copy the private runtime (TUTK libs, bionic, bridge binary) from /config into the image workdir
# 2) make the ARM64 Android bridge runnable on this x86_64 host through qemu-user
# 3) hand over to the upstream supervisor (reads /data/options.json)
set -euo pipefail

SRC=/config/ebo-se/runtime
DEST=/opt/ebo

mkdir -p "$DEST/bionic" "$DEST/lib"

if [ ! -d "$SRC" ]; then
  echo "[addon] FATAL: $SRC not found."
  echo "[addon] put linker/libc/libm/libdl/libc++/liblog/libstdc++/libnetd_client in $SRC/bionic,"
  echo "[addon] the four libTUTK*.so in $SRC/lib, and ebo_bridge-arm64 in $SRC/."
  exit 2
fi

cp -f "$SRC"/bionic/* "$DEST/bionic"/ 2>/dev/null || true
cp -f "$SRC"/lib/*.so   "$DEST/lib"/    2>/dev/null || true
cp -f "$SRC"/ebo_bridge-arm64 "$DEST"/  2>/dev/null || true
if [ -f "$SRC/ioctl9930.bin" ]; then cp -f "$SRC/ioctl9930.bin" "$DEST/"; fi

chmod +x "$DEST/bionic/linker" "$DEST/ebo_bridge-arm64" "$DEST/mediamtx" "$DEST/run.sh" 2>/dev/null || true

if [ ! -x "$DEST/bionic/linker" ] || [ ! -x "$DEST/ebo_bridge-arm64" ]; then
  echo "[addon] FATAL: bionic/linker or ebo_bridge-arm64 missing in $SRC"; exit 2
fi

# ARM64 Android binaries: on an x86_64 glibc host translate with qemu-user;
# on an aarch64 host they run natively (no qemu needed).
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
  export EBO_QEMU=/usr/bin/qemu-aarch64-static
else
  unset EBO_QEMU || true
fi
export EBO_BRIDGE_BIN=ebo_bridge-arm64
export EBO_DIR="$DEST"
export EBO_PORT="${EBO_PORT:-8000}"

echo "[addon] arch=$(dpkg --print-architecture) qemu=${EBO_QEMU:-native}"
echo "[addon] libs: $(ls -1 "$DEST/lib" | tr '\n' ' ')"

exec bash "$DEST/run.sh"
