lib_LTLIBRARIES = libmobileffmpeg.la

libmobileffmpeg_la_LIBADD = @FFMPEG_LIBS@

libmobileffmpeg_la_SOURCES = \
    ArchDetect.m \
    AtomicLong.m \
    fftools_stub.c \
    FFmpegExecution.m \
    MediaInformation.m \
    MediaInformationParser.m \
    MobileFFmpeg.m \
    MobileFFmpegConfig.m \
    mobileffmpeg_exception.m \
    MobileFFprobe.m \
    Statistics.m \
    StreamInformation.m

# 仅音频解码构建不包含 avfilter/swscale，fftools_* 命令行实现改用 fftools_stub.c，
# fftools_ffmpeg_videotoolbox.c 同样不再编译。

include_HEADERS = \
    ArchDetect.h \
    AtomicLong.h \
    ExecuteDelegate.h \
    FFmpegExecution.h \
	fftools_cmdutils.h \
    fftools_ffmpeg.h \
	LogDelegate.h \
	MediaInformation.h \
	MediaInformationParser.h \
    MobileFFmpeg.h \
    MobileFFmpegConfig.h \
	mobileffmpeg_exception.h \
	MobileFFprobe.h \
	Statistics.h \
	StatisticsDelegate.h \
	StreamInformation.h

libmobileffmpeg_la_CFLAGS = $(CFLAGS)
libmobileffmpeg_la_OBJCFLAGS = $(CFLAGS)
libmobileffmpeg_la_CXXFLAGS = $(CXXFLAGS)
libmobileffmpeg_la_LDFLAGS = $(LDFLAGS)
