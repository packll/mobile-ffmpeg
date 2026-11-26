#!/bin/bash
#
# 编译 iOS 模拟器用的 FFmpeg 静态库（音频解码裁剪，与 ios.sh 口径一致）。
#
# 用法:
#   bash ios-simulator.sh            # 默认 arm64（Apple Silicon 模拟器）
#   bash ios-simulator.sh x86_64     # Intel 模拟器
#
# 产物: ../ffmpegLib/ios-simulator-<arch>/ffmpeg/{lib,include}

set -e

export BASEDIR=$(pwd)
export PREBUILT_DIR="${PREBUILT_DIR:-${BASEDIR}/../ffmpegLib}"
SIM_ARCH=${1:-arm64}
FFMPEG_SOURCE_DIR="${BASEDIR}/src/ffmpeg"
LOG_FILE="${BASEDIR}/build.log"

SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
CLANG=$(xcrun --sdk iphonesimulator -f clang)
MIN_VERSION=12.1

if [[ ${SIM_ARCH} == "arm64" ]]; then
  TARGET="arm64-apple-ios${MIN_VERSION}-simulator"
  FFMPEG_ARCH="aarch64"
  FFMPEG_CPU="armv8"
  ARCH_OPTIONS="--enable-neon --enable-asm --enable-inline-asm"
elif [[ ${SIM_ARCH} == "x86_64" ]]; then
  TARGET="x86_64-apple-ios${MIN_VERSION}-simulator"
  FFMPEG_ARCH="x86_64"
  FFMPEG_CPU="x86_64"
  ARCH_OPTIONS="--disable-asm --disable-inline-asm"
else
  echo "error: unsupported simulator arch ${SIM_ARCH} (arm64|x86_64)"
  exit 1
fi

VARIANT="ios-simulator-${SIM_ARCH}"
PREFIX="${PREBUILT_DIR}/${VARIANT}/ffmpeg"
CC="${CLANG} -target ${TARGET} -isysroot ${SDK_PATH}"

echo "Building FFmpeg for iOS Simulator ${SIM_ARCH}"
echo "  SDK: ${SDK_PATH}"
echo "  Output: ${PREFIX}"

cd "${FFMPEG_SOURCE_DIR}"
make distclean >/dev/null 2>&1 || true
find . \( -name "*.o" -o -name "*.d" -o -name "*.lo" \) -delete

./configure \
  --prefix="${PREFIX}" \
  --enable-version3 \
  --arch="${FFMPEG_ARCH}" \
  --cpu="${FFMPEG_CPU}" \
  --target-os=darwin \
  --cc="${CC}" \
  --cxx="${CLANG}++ -target ${TARGET} -isysroot ${SDK_PATH}" \
  --ar="$(xcrun -f ar)" \
  --ranlib="$(xcrun -f ranlib)" \
  --strip="$(xcrun -f strip)" \
  --sysroot="${SDK_PATH}" \
  ${ARCH_OPTIONS} \
  --enable-cross-compile \
  --enable-pic \
  --enable-optimizations \
  --enable-static \
  --disable-shared \
  --enable-small \
  --disable-debug \
  --disable-programs \
  --disable-postproc \
  --disable-doc \
  --disable-htmlpages \
  --disable-manpages \
  --disable-podpages \
  --disable-txtpages \
  --disable-symver \
  --disable-stripping \
  --enable-network \
  --disable-zlib \
  --disable-bzlib \
  --disable-iconv \
  --disable-openssl \
  --disable-securetransport \
  --disable-schannel \
  --disable-xlib \
  --disable-cuda \
  --disable-cuvid \
  --disable-nvenc \
  --disable-vaapi \
  --disable-vdpau \
  --disable-videotoolbox \
  --disable-audiotoolbox \
  --disable-appkit \
  --disable-alsa \
  --disable-gpl \
  --disable-nonfree \
  --disable-gray \
  --disable-swscale-alpha \
  --disable-avdevice \
  --disable-avfilter \
  --disable-swscale \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swresample \
  --disable-encoders \
  --disable-decoders \
  --enable-decoder=aac \
  --enable-decoder=aac_latm \
  --enable-decoder=mp3* \
  --enable-decoder=flac \
  --enable-decoder=wmav1 \
  --enable-decoder=wmav2 \
  --enable-decoder=wavpack \
  --enable-decoder=wav \
  --enable-decoder=pcm_s16le \
  --disable-devices \
  --disable-filters \
  --disable-ffprobe \
  --disable-ffplay \
  --disable-ffmpeg 1>>${LOG_FILE} 2>&1

make -j"$(sysctl -n hw.ncpu)" 1>>${LOG_FILE} 2>&1
rm -rf "${PREFIX}"
make install 1>>${LOG_FILE} 2>&1

mkdir -p "${PREFIX}/include/libavutil/x86" "${PREFIX}/include/libavutil/arm" \
  "${PREFIX}/include/libavutil/aarch64" "${PREFIX}/include/libavcodec/x86" \
  "${PREFIX}/include/libavcodec/arm"
cp -f config.h "${PREFIX}/include" 2>/dev/null || true
cp -f libavcodec/mathops.h "${PREFIX}/include/libavcodec" 2>/dev/null || true
cp -f libavcodec/x86/mathops.h "${PREFIX}/include/libavcodec/x86" 2>/dev/null || true
cp -f libavcodec/arm/mathops.h "${PREFIX}/include/libavcodec/arm" 2>/dev/null || true
cp -f libavformat/network.h "${PREFIX}/include/libavformat" 2>/dev/null || true
cp -f libavformat/os_support.h "${PREFIX}/include/libavformat" 2>/dev/null || true
cp -f libavformat/url.h "${PREFIX}/include/libavformat" 2>/dev/null || true
cp -f libavutil/internal.h "${PREFIX}/include/libavutil" 2>/dev/null || true
cp -f libavutil/libm.h "${PREFIX}/include/libavutil" 2>/dev/null || true
cp -f libavutil/reverse.h "${PREFIX}/include/libavutil" 2>/dev/null || true
cp -f libavutil/thread.h "${PREFIX}/include/libavutil" 2>/dev/null || true
cp -f libavutil/timer.h "${PREFIX}/include/libavutil" 2>/dev/null || true
cp -f libavutil/x86/asm.h "${PREFIX}/include/libavutil/x86" 2>/dev/null || true
cp -f libavutil/x86/timer.h "${PREFIX}/include/libavutil/x86" 2>/dev/null || true
cp -f libavutil/arm/timer.h "${PREFIX}/include/libavutil/arm" 2>/dev/null || true
cp -f libavutil/aarch64/timer.h "${PREFIX}/include/libavutil/aarch64" 2>/dev/null || true
cp -f libavutil/x86/emms.h "${PREFIX}/include/libavutil/x86" 2>/dev/null || true

echo "ok: ${PREFIX}"
