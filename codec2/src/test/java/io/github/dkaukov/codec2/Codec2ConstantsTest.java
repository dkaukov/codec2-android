package io.github.dkaukov.codec2;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class Codec2ConstantsTest {
    @Test
    public void mode1300FrameGeometryIsStable() {
        assertEquals(320, Codec2.PCM_SAMPLES);
        assertEquals(7, Codec2.FRAME_BYTES);
    }
}
