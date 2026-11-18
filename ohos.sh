#!/bin/bash
#
# 在 macOS 上为 HarmonyOS (OHOS) 交叉编译 FFmpeg，只编译音频解码相关的
# avcodec / avformat / avutil / swresample，与 android.sh / ios.sh 的裁剪口径一致。
#
# 用法:
#   bash ohos.sh                          # 默认编译 arm64-v8a + x86_64
#   bash ohos.sh --enable-arm-v7a         # 额外编译 armeabi-v7a
#   bash ohos.sh --disable-x86-64         # 只编译 arm64-v8a
#   bash ohos.sh --disable-arm64          # 不编译 arm64-v8a
#
# NDK 通过 OHOS_NDK_HOME 指定；未设置时自动从 DEVECO_SDK_HOME 或
# DevEco Studio 默认安装路径查找 default/openharmony/native。
#
# 产物: prebuilt/ohos-<abi>/ffmpeg/{lib,include}

set -u

export BASEDIR=$(pwd)
FFMPEG_SOURCE_DIR="${BASEDIR}/src/ffmpeg"
LOG_FILE="${BASEDIR}/build.log"

# ABI 开关: arm64-v8a / armeabi-v7a / x86_64
BUILD_ARM64=1
BUILD_ARMV7=0
BUILD_X86_64=1

display_help() {
  echo "ohos.sh builds FFmpeg for HarmonyOS (OHOS)."
  echo "Only audio decoder related libraries are built (avcodec/avformat/avutil/swresample)."
  echo ""
  echo "Usage: bash ohos.sh [OPTION]..."
  echo ""
  echo "  -h, --help           display this help and exit"
  echo "  --enable-arm-v7a     also build armeabi-v7a [no]"
  echo "  --disable-arm64      do not build arm64-v8a [yes]"
  echo "  --disable-x86-64     do not build x86_64 simulator [yes]"
  echo ""
  echo "Environment:"
  echo "  OHOS_NDK_HOME        path of openharmony/native in the OHOS SDK"
  echo "  DEVECO_SDK_HOME      used to locate default/openharmony/native automatically"
}

while [ $# -gt 0 ]; do
  case $1 in
  -h | --help)
    display_help
    exit 0
    ;;
  --enable-arm-v7a)
    BUILD_ARMV7=1
    ;;
  --disable-arm64)
    BUILD_ARM64=0
    ;;
  --disable-x86-64)
    BUILD_X86_64=0
    ;;
  *)
    echo "Unknown option \"$1\". See bash ohos.sh --help."
    exit 1
    ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# 定位 OHOS NDK
# ---------------------------------------------------------------------------
find_ohos_ndk() {
  local candidates=()
  if [[ -n ${OHOS_NDK_HOME:-} ]]; then
    candidates+=("${OHOS_NDK_HOME}")
  fi
  if [[ -n ${DEVECO_SDK_HOME:-} ]]; then
    candidates+=("${DEVECO_SDK_HOME}/default/openharmony/native")
  fi
  candidates+=("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native")

  for candidate in "${candidates[@]}"; do
    if [[ -x "${candidate}/llvm/bin/clang" ]] && [[ -d "${candidate}/sysroot" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

OHOS_NDK=$(find_ohos_ndk) || {
  echo "error: OHOS NDK not found. Set OHOS_NDK_HOME to <sdk>/default/openharmony/native."
  exit 1
}

OHOS_LLVM_BIN="${OHOS_NDK}/llvm/bin"
OHOS_SYSROOT="${OHOS_NDK}/sysroot"

if [[ ! -f ${FFMPEG_SOURCE_DIR}/configure ]]; then
  echo "error: FFmpeg source not found at ${FFMPEG_SOURCE_DIR}"
  echo "Run bash android.sh or bash ios.sh once to download it, or clone FFmpeg into src/ffmpeg."
  exit 1
fi

echo "INFO: Using OHOS NDK at ${OHOS_NDK}"
echo "INFO: FFmpeg source at ${FFMPEG_SOURCE_DIR}"

CPU_COUNT=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)

# ---------------------------------------------------------------------------
# 单个 ABI 的编译
#   $1 = Android 风格 ABI 名（用于输出目录），同时决定 OHOS target
# ---------------------------------------------------------------------------
build_abi() {
  local ABI=$1
  local OHOS_TARGET=""
  local FFMPEG_ARCH=""
  local FFMPEG_CPU=""
  local ARCH_OPTIONS=""

  case ${ABI} in
  arm64-v8a)
    OHOS_TARGET="aarch64-linux-ohos"
    FFMPEG_ARCH="aarch64"
    FFMPEG_CPU="armv8-a"
    ARCH_OPTIONS="--enable-neon --enable-asm --enable-inline-asm"
    ;;
  armeabi-v7a)
    OHOS_TARGET="arm-linux-ohos"
    FFMPEG_ARCH="armv7-a"
    FFMPEG_CPU="armv7-a"
    ARCH_OPTIONS="--disable-neon --enable-asm --enable-inline-asm"
    ;;
  x86_64)
    OHOS_TARGET="x86_64-linux-ohos"
    FFMPEG_ARCH="x86_64"
    FFMPEG_CPU="x86_64"
    # 避免依赖 nasm/yasm
    ARCH_OPTIONS="--disable-asm --disable-inline-asm"
    ;;
  *)
    echo "error: unsupported ABI ${ABI}"
    return 1
    ;;
  esac

  local PREFIX="${BASEDIR}/prebuilt/ohos-${ABI}/ffmpeg"
  local CC="${OHOS_LLVM_BIN}/clang --target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT}"

  echo ""
  echo "Building FFmpeg for OHOS ${ABI} (${OHOS_TARGET})"

  cd ${FFMPEG_SOURCE_DIR} || return 1
  make distclean >/dev/null 2>&1

  # distclean 可能遗留之前 Android/iOS 构建（含 LTO/bitcode）产生的对象文件，
  # 切换 ABI 前彻底清理，避免链接时报 "is incompatible with elf_x86_64" 等错误。
  find ${FFMPEG_SOURCE_DIR} \( -name "*.o" -o -name "*.d" -o -name "*.lo" \) -delete

  ./configure \
    --prefix="${PREFIX}" \
    --enable-version3 \
    --arch="${FFMPEG_ARCH}" \
    --cpu="${FFMPEG_CPU}" \
    --target-os=linux \
    --cc="${CC}" \
    --cxx="${OHOS_LLVM_BIN}/clang++ --target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT}" \
    --ld="${CC}" \
    --ar="${OHOS_LLVM_BIN}/llvm-ar" \
    --ranlib="${OHOS_LLVM_BIN}/llvm-ranlib" \
    --nm="${OHOS_LLVM_BIN}/llvm-nm" \
    --strip="${OHOS_LLVM_BIN}/llvm-strip" \
    --sysroot="${OHOS_SYSROOT}" \
    ${ARCH_OPTIONS} \
    --enable-cross-compile \
    --enable-pic \
    --enable-optimizations \
    --enable-shared \
    --disable-static \
    --enable-small \
    --disable-debug \
    --disable-lto \
    --disable-programs \
    --disable-postproc \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-symver \
    --disable-stripping \
    --disable-jni \
    --disable-mediacodec \
    --disable-v4l2-m2m \
    --disable-indev=fbdev \
    --disable-outdev=fbdev \
    --disable-alsa \
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
    --enable-network \
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

  if [ $? -ne 0 ]; then
    echo "error: FFmpeg configure failed for ${ABI}. See ${LOG_FILE} and src/ffmpeg/ffbuild/config.log"
    return 1
  fi

  make -j${CPU_COUNT} 1>>${LOG_FILE} 2>&1
  if [ $? -ne 0 ]; then
    echo "error: FFmpeg make failed for ${ABI}. See ${LOG_FILE}"
    return 1
  fi

  rm -rf "${PREFIX}"
  make install 1>>${LOG_FILE} 2>&1
  if [ $? -ne 0 ]; then
    echo "error: FFmpeg install failed for ${ABI}. See ${LOG_FILE}"
    return 1
  fi

  # 与 Android 构建保持一致，补上包装层/业务代码常用的内部头文件
  mkdir -p "${PREFIX}/include/libavutil/x86" "${PREFIX}/include/libavutil/arm" \
    "${PREFIX}/include/libavutil/aarch64" "${PREFIX}/include/libavcodec/x86" \
    "${PREFIX}/include/libavcodec/arm"
  cp -f ${FFMPEG_SOURCE_DIR}/config.h "${PREFIX}/include" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavcodec/mathops.h "${PREFIX}/include/libavcodec" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavcodec/x86/mathops.h "${PREFIX}/include/libavcodec/x86" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavcodec/arm/mathops.h "${PREFIX}/include/libavcodec/arm" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavformat/network.h "${PREFIX}/include/libavformat" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavformat/os_support.h "${PREFIX}/include/libavformat" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavformat/url.h "${PREFIX}/include/libavformat" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/internal.h "${PREFIX}/include/libavutil" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/libm.h "${PREFIX}/include/libavutil" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/reverse.h "${PREFIX}/include/libavutil" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/thread.h "${PREFIX}/include/libavutil" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/timer.h "${PREFIX}/include/libavutil" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/x86/asm.h "${PREFIX}/include/libavutil/x86" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/x86/timer.h "${PREFIX}/include/libavutil/x86" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/arm/timer.h "${PREFIX}/include/libavutil/arm" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/aarch64/timer.h "${PREFIX}/include/libavutil/aarch64" 2>/dev/null
  cp -f ${FFMPEG_SOURCE_DIR}/libavutil/x86/emms.h "${PREFIX}/include/libavutil/x86" 2>/dev/null

  echo "ok: ${PREFIX}"
  ls -1 "${PREFIX}/lib"/*.so 2>/dev/null
}

RESULT=0
if [[ ${BUILD_ARM64} -eq 1 ]]; then
  build_abi "arm64-v8a" || RESULT=1
fi
if [[ ${BUILD_ARMV7} -eq 1 ]]; then
  build_abi "armeabi-v7a" || RESULT=1
fi
if [[ ${BUILD_X86_64} -eq 1 ]]; then
  build_abi "x86_64" || RESULT=1
fi

if [[ ${RESULT} -ne 0 ]]; then
  exit 1
fi

echo ""
echo "FFmpeg for OHOS built successfully. Libraries are under ${BASEDIR}/prebuilt/ohos-*/ffmpeg"
