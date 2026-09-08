package io.github.dkaukov.codec2;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class Codec2InstrumentedTest {
    @Test
    public void validatesArraySizes() {
        try (Codec2 codec2 = new Codec2()) {
            assertThrows(IllegalArgumentException.class,
                    () -> codec2.encode(new short[Codec2.PCM_SAMPLES - 1], new byte[Codec2.FRAME_BYTES]));
            assertThrows(IllegalArgumentException.class,
                    () -> codec2.encode(new short[Codec2.PCM_SAMPLES], new byte[Codec2.FRAME_BYTES + 1]));
            assertThrows(IllegalArgumentException.class,
                    () -> codec2.decode(new byte[Codec2.FRAME_BYTES], new short[Codec2.PCM_SAMPLES + 1]));
        }
    }

    @Test
    public void closeIsIdempotentAndOperationsAfterCloseFail() {
        Codec2 codec2 = new Codec2();
        codec2.close();
        codec2.close();
        assertThrows(IllegalStateException.class,
                () -> codec2.encode(new short[Codec2.PCM_SAMPLES], new byte[Codec2.FRAME_BYTES]));
    }

    @Test
    public void nativeEncodeDecodeRoundTripProducesAudio() {
        short[] input = new short[Codec2.PCM_SAMPLES];
        for (int i = 0; i < input.length; ++i) {
            input[i] = (short) (10_000.0 * Math.sin(2.0 * Math.PI * 440.0 * i / 8_000.0));
        }
        byte[] frame = new byte[Codec2.FRAME_BYTES];
        short[] output = new short[Codec2.PCM_SAMPLES];

        try (Codec2 codec2 = new Codec2()) {
            codec2.encode(input, frame);
            codec2.decode(frame, output);
        }

        assertEquals(0, frame[Codec2.FRAME_BYTES - 1] & 0x0f);
        boolean hasAudio = false;
        for (short sample : output) {
            hasAudio |= sample != 0;
        }
        assertTrue("decoded frame should contain non-zero audio", hasAudio);
    }
}
