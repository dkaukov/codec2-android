#include <jni.h>

#include <cstdint>

#include "codec2.h"

namespace {

constexpr jsize kPcmSamples = 320;
constexpr jsize kFrameBytes = 7;

void throwException(JNIEnv *env, const char *className, const char *message) {
    jclass exceptionClass = env->FindClass(className);
    if (exceptionClass != nullptr) {
        env->ThrowNew(exceptionClass, message);
    }
}

CODEC2 *requireCodec(JNIEnv *env, jlong handle) {
    auto *codec = reinterpret_cast<CODEC2 *>(handle);
    if (codec == nullptr) {
        throwException(env, "java/lang/IllegalStateException", "Codec2 is closed");
    }
    return codec;
}

bool requireArrayLengths(JNIEnv *env, jshortArray pcm, jbyteArray frame) {
    if (pcm == nullptr || frame == nullptr) {
        throwException(env, "java/lang/NullPointerException", "Codec2 arrays must not be null");
        return false;
    }
    if (env->GetArrayLength(pcm) != kPcmSamples || env->GetArrayLength(frame) != kFrameBytes) {
        throwException(env, "java/lang/IllegalArgumentException",
                       "Codec2 requires exactly 320 PCM samples and a 7-byte frame");
        return false;
    }
    return true;
}

}  // namespace

extern "C" JNIEXPORT jlong JNICALL
Java_io_github_dkaukov_codec2_Codec2_nativeCreate(JNIEnv *, jclass) {
    return reinterpret_cast<jlong>(codec2_create(CODEC2_MODE_1300));
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_dkaukov_codec2_Codec2_nativeDestroy(JNIEnv *, jclass, jlong handle) {
    if (handle != 0) {
        codec2_destroy(reinterpret_cast<CODEC2 *>(handle));
    }
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_dkaukov_codec2_Codec2_nativeEncode(JNIEnv *env, jclass, jlong handle,
                                                   jshortArray pcm, jbyteArray frame) {
    CODEC2 *codec = requireCodec(env, handle);
    if (codec == nullptr || !requireArrayLengths(env, pcm, frame)) {
        return;
    }

    jshort *pcmData = env->GetShortArrayElements(pcm, nullptr);
    jbyte *frameData = env->GetByteArrayElements(frame, nullptr);
    if (pcmData == nullptr || frameData == nullptr) {
        if (pcmData != nullptr) env->ReleaseShortArrayElements(pcm, pcmData, JNI_ABORT);
        if (frameData != nullptr) env->ReleaseByteArrayElements(frame, frameData, JNI_ABORT);
        return;
    }

    codec2_encode(codec, reinterpret_cast<unsigned char *>(frameData), pcmData);
    env->ReleaseByteArrayElements(frame, frameData, 0);
    env->ReleaseShortArrayElements(pcm, pcmData, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_dkaukov_codec2_Codec2_nativeDecode(JNIEnv *env, jclass, jlong handle,
                                                   jbyteArray frame, jshortArray pcm) {
    CODEC2 *codec = requireCodec(env, handle);
    if (codec == nullptr || !requireArrayLengths(env, pcm, frame)) {
        return;
    }

    jbyte *frameData = env->GetByteArrayElements(frame, nullptr);
    jshort *pcmData = env->GetShortArrayElements(pcm, nullptr);
    if (frameData == nullptr || pcmData == nullptr) {
        if (frameData != nullptr) env->ReleaseByteArrayElements(frame, frameData, JNI_ABORT);
        if (pcmData != nullptr) env->ReleaseShortArrayElements(pcm, pcmData, JNI_ABORT);
        return;
    }

    codec2_decode(codec, pcmData, reinterpret_cast<unsigned char *>(frameData));
    env->ReleaseShortArrayElements(pcm, pcmData, 0);
    env->ReleaseByteArrayElements(frame, frameData, JNI_ABORT);
}
