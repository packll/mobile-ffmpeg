/*
 * 当前工程只编译音频解码相关的 FFmpeg 库（libavcodec/libavformat/libavutil/libswresample），
 * fftools_ffmpeg.c / fftools_ffprobe.c 依赖的 avfilter、avdevice、swscale 均未构建，
 * 因此不再编译这些命令行实现。
 *
 * 这里保留 mobileffmpeg.c / mobileffprobe.c 需要的符号，避免 JNI 层链接失败。
 * 调用 FFmpeg.execute / FFprobe.execute 会返回非 0 并输出提示日志。
 */
#include <android/log.h>
#include <stdint.h>

#define STUB_TAG "mobile-ffmpeg"
#define STUB_LOG(...) __android_log_print(ANDROID_LOG_WARN, STUB_TAG, __VA_ARGS__)

int ffmpeg_execute(int argc, char **argv) {
    (void) argc;
    (void) argv;
    STUB_LOG("ffmpeg command line is not available in this audio-decoder-only build.");
    return -1;
}

int ffprobe_execute(int argc, char **argv) {
    (void) argc;
    (void) argv;
    STUB_LOG("ffprobe command line is not available in this audio-decoder-only build.");
    return -1;
}

void cancel_operation(long id) {
    (void) id;
}

void set_report_callback(void (*callback)(int, float, float, int64_t, int, double, double)) {
    (void) callback;
}
