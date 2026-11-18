/*
 * iOS 构建与 Android 一样只保留音频解码相关的 FFmpeg 库，
 * avfilter / swscale 未编译，fftools_ffmpeg.c / fftools_ffprobe.c 等命令行实现因此不再参与构建。
 *
 * 这里保留 MobileFFmpeg.m / MobileFFprobe.m / MobileFFmpegConfig.m 需要的符号，
 * 调用 [MobileFFmpeg execute] / [MobileFFprobe execute] 会返回非 0 并输出提示。
 */
#include <stdint.h>
#include <stdio.h>

int ffmpeg_execute(int argc, char **argv) {
    (void) argc;
    (void) argv;
    fprintf(stderr, "mobile-ffmpeg: ffmpeg command line is not available in this audio-decoder-only build.\n");
    return -1;
}

int ffprobe_execute(int argc, char **argv) {
    (void) argc;
    (void) argv;
    fprintf(stderr, "mobile-ffmpeg: ffprobe command line is not available in this audio-decoder-only build.\n");
    return -1;
}

void cancel_operation(long id) {
    (void) id;
}

void set_report_callback(void (*callback)(int, float, float, int64_t, int, double, double)) {
    (void) callback;
}
