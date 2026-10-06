package com.bloom.wadhakir

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The decode-time downsampling rule. See [BitmapSampling] for why a wrong answer
 * either blurs a wallpaper or brings back the full-resolution decode.
 */
class BitmapSamplingTest {

    @Test
    fun `the images the app actually draws are decoded at full size`() {
        // Islamic-backgrounds wallpaper: the 9:16 IslamicCanvas, ~360 logical
        // px wide at pixelRatio 3.5, on a 1080x2400 phone and on a 720x1600
        // one. Neither may lose a pixel.
        assertEquals(1, BitmapSampling.inSampleSize(1260, 2240, 1080, 2400))
        assertEquals(1, BitmapSampling.inSampleSize(1260, 2240, 720, 1600))
        // Glass home-screen widgets: 360x172 logical at pixelRatio 3.0.
        assertEquals(1, BitmapSampling.inSampleSize(1080, 516, 1080, 2400))
    }

    @Test
    fun `an image twice the screen in both directions is halved`() {
        assertEquals(2, BitmapSampling.inSampleSize(2160, 4800, 1080, 2400))
    }

    @Test
    fun `sampling stops before either side drops below the target`() {
        // 4x would make the long side 1200, under the 2400 the screen needs.
        assertEquals(2, BitmapSampling.inSampleSize(4320, 4800, 1080, 2400))
        // One pixel short of 2x on the long side: no sampling at all.
        assertEquals(1, BitmapSampling.inSampleSize(2160, 4799, 1080, 2400))
    }

    @Test
    fun `a very large photo is reduced by the largest power of two that still fits`() {
        // A 48 MP camera photo (6000x8000) for a 1080x2400 screen: 8000 / 4 =
        // 2000 is under 2400, so only 2x is allowed.
        assertEquals(2, BitmapSampling.inSampleSize(6000, 8000, 1080, 2400))
        assertEquals(4, BitmapSampling.inSampleSize(6000, 12000, 1080, 2400))
    }

    @Test
    fun `orientation does not matter`() {
        // The phone is held sideways when the wallpaper is set: the portrait
        // image must still be judged against the portrait screen it will fill.
        assertEquals(
            BitmapSampling.inSampleSize(2160, 4800, 1080, 2400),
            BitmapSampling.inSampleSize(2160, 4800, 2400, 1080),
        )
        assertEquals(
            BitmapSampling.inSampleSize(2160, 4800, 1080, 2400),
            BitmapSampling.inSampleSize(4800, 2160, 1080, 2400),
        )
    }

    @Test
    fun `an unknown size never samples`() {
        // WallpaperManager reports a desired size of 0 or -1 when the launcher
        // has none, and a failed bounds decode reports -1.
        assertEquals(1, BitmapSampling.inSampleSize(-1, -1, 1080, 2400))
        assertEquals(1, BitmapSampling.inSampleSize(4000, 8000, 0, 2400))
        assertEquals(1, BitmapSampling.inSampleSize(4000, 8000, 1080, -1))
    }
}
