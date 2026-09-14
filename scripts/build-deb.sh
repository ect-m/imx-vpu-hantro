#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT_DIR:-$ROOT/out}
VERSION=${PACKAGE_VERSION:-1.9.0-6.18.20-ecd-imx8m}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
source "$ROOT/sources.env"

printf '%s  %s\n' "$HANTRO_SHA256" "$ROOT/sources/$HANTRO_ARCHIVE" | sha256sum -c -
printf '%s  %s\n' "$VC_SHA256" "$ROOT/sources/$VC_ARCHIVE" | sha256sum -c -
printf '%s  %s\n' "$DAEMON_SHA256" "$ROOT/sources/$DAEMON_ARCHIVE" | sha256sum -c -

tar -xzf "$ROOT/sources/$HANTRO_ARCHIVE" -C "$WORK"
tar -xzf "$ROOT/sources/$VC_ARCHIVE" -C "$WORK"
mkdir -p "$WORK/daemon"
tar -xzf "$ROOT/sources/$DAEMON_ARCHIVE" -C "$WORK/daemon" --strip-components=1

H="$WORK/imx-vpu-hantro-$HANTRO_VERSION"
VC="$WORK/imx-vpu-hantro-vc-$VC_VERSION"
DAE="$WORK/daemon/v4l2_vsi_daemon"
CTRL="$WORK/ctrlsw"
mkdir -p "$CTRL/hantro_dec" "$CTRL/hantro_VC8000E_enc"
cp "$H"/decoder_sw/software/source/inc/*.h "$CTRL/hantro_dec/"
cp "$VC"/usr/include/hantro_VC8000E_enc/*.h "$CTRL/hantro_VC8000E_enc/"

export CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-}
export CC="${CROSS_COMPILE}gcc -std=gnu11"
export CXX="${CROSS_COMPILE}g++ -std=gnu++11"
export AR="${CROSS_COMPILE}ar"
export CFLAGS="-I$ROOT/kernel-uapi"

make -C "$H" -f Makefile_G1G2 clean >/dev/null 2>&1 || true
make -C "$H" -f Makefile_G1G2 libhantro.so libhantro.a libg1.so libg1.a libcodec
find "$H" -name 'lib*.so*' -exec cp -P {} "$DAE/" \;
cp -P "$VC"/usr/lib/libhantro_vc8000e.so* "$DAE/"

make -C "$DAE" clean >/dev/null 2>&1 || true
make -C "$DAE" target=865 CTRLSW_HDRPATH="$CTRL" SDKTARGETSYSROOT= CC="$CC" CXX="$CXX"

PKG="$WORK/pkg"
mkdir -p "$PKG/DEBIAN" "$PKG/usr/local/bin" "$PKG/usr/bin" "$PKG/usr/lib"
install -m 0755 "$DAE/vsidaemon" "$PKG/usr/local/bin/vsiv4l2daemon"
ln -s /usr/local/bin/vsiv4l2daemon "$PKG/usr/bin/vsidaemon"
cp -P "$DAE"/lib*.so* "$PKG/usr/lib/"
cp -P "$VC"/usr/lib/libhantro_vc8000e.so* "$PKG/usr/lib/"

cat > "$PKG/DEBIAN/control" <<EOF
Package: imx-vpu-hantro
Version: $VERSION
Architecture: arm64
Maintainer: Pi.MX8 Project
Depends: libc6
Description: NXP i.MX8MP VPU userspace for Pi.MX8
 Combined VC8000E, Hantro G1/G2, and vsiv4l2daemon userspace.
 Built for kernel ABI $KERNEL_ABI.
EOF
mkdir -p "$OUT"
dpkg-deb --build --root-owner-group "$PKG" "$OUT/imx-vpu-hantro_${VERSION}_arm64.deb"
dpkg-deb -I "$OUT/imx-vpu-hantro_${VERSION}_arm64.deb"
dpkg-deb -c "$OUT/imx-vpu-hantro_${VERSION}_arm64.deb" | grep -E 'vsiv4l2daemon|lib(hantro|g1|codec)' 
