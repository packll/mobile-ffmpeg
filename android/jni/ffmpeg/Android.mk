LOCAL_PATH := $(call my-dir)/../../../../ffmpegLib/android-$(TARGET_ARCH)/ffmpeg/lib

MY_ARM_MODE := arm

include $(CLEAR_VARS)
LOCAL_ARM_MODE := $(MY_ARM_MODE)
LOCAL_MODULE := libavcodec
LOCAL_SRC_FILES := libavcodec.so
include $(PREBUILT_SHARED_LIBRARY)

# android-ffmpeg.sh 使用 --disable-avfilter/--disable-avdevice/--disable-swscale，
# 不会生成 libavfilter.so / libavdevice.so / libswscale.so，这里不再声明对应模块。

include $(CLEAR_VARS)
LOCAL_ARM_MODE := $(MY_ARM_MODE)
LOCAL_MODULE := libavformat
LOCAL_SRC_FILES := libavformat.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_ARM_MODE := $(MY_ARM_MODE)
LOCAL_MODULE := libavutil
LOCAL_SRC_FILES := libavutil.so
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/../include
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_ARM_MODE := $(MY_ARM_MODE)
LOCAL_MODULE := libswresample
LOCAL_SRC_FILES := libswresample.so
include $(PREBUILT_SHARED_LIBRARY)
