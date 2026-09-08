package io.github.dkaukov.codec2;

import java.util.Objects;

/** Minimal stateful Android wrapper for Codec2 mode 1300. */
public final class Codec2 implements AutoCloseable {
    public static final int PCM_SAMPLES = 320;
    public static final int FRAME_BYTES = 7;
    private static final String FRAME_PARAMETER = "frame";

    static {
        System.loadLibrary("codec2-android");
    }

    private long handle;

    public Codec2() {
        handle = nativeCreate();
        if (handle == 0) {
            throw new IllegalStateException("Codec2 mode 1300 is unavailable");
        }
    }

    public synchronized void encode(short[] pcm, byte[] frame) {
        requireOpen();
        requireLength(Objects.requireNonNull(pcm, "pcm"), PCM_SAMPLES, "pcm");
        requireLength(Objects.requireNonNull(frame, FRAME_PARAMETER), FRAME_BYTES, FRAME_PARAMETER);
        nativeEncode(handle, pcm, frame);
    }

    public synchronized void decode(byte[] frame, short[] pcm) {
        requireOpen();
        requireLength(Objects.requireNonNull(frame, FRAME_PARAMETER), FRAME_BYTES, FRAME_PARAMETER);
        requireLength(Objects.requireNonNull(pcm, "pcm"), PCM_SAMPLES, "pcm");
        nativeDecode(handle, frame, pcm);
    }

    private void requireOpen() {
        if (handle == 0) {
            throw new IllegalStateException("Codec2 is closed");
        }
    }

    private static void requireLength(short[] value, int expected, String name) {
        if (value.length != expected) {
            throw new IllegalArgumentException(name + " must contain exactly " + expected + " elements");
        }
    }

    private static void requireLength(byte[] value, int expected, String name) {
        if (value.length != expected) {
            throw new IllegalArgumentException(name + " must contain exactly " + expected + " elements");
        }
    }

    @Override
    public synchronized void close() {
        if (handle != 0) {
            nativeDestroy(handle);
            handle = 0;
        }
    }

    private static native long nativeCreate();
    private static native void nativeDestroy(long handle);
    private static native void nativeEncode(long handle, short[] pcm, byte[] frame);
    private static native void nativeDecode(long handle, byte[] frame, short[] pcm);
}
