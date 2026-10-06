package com.bloom.wadhakir

/**
 * How much to shrink an image while decoding it, so it is never held in memory
 * at more pixels than the screen showing it can use.
 *
 * The decoding lives in [SampledBitmap]; the deciding lives here, with no
 * Android types, for the same reason [ReminderRules] exists: a wrong answer
 * fails silently. Too eager and a wallpaper comes out visibly blurred; too timid
 * and a large image is decoded at full resolution — Play Console's "bitmap
 * downsampling" warning, and on a low-memory phone an OutOfMemoryError, which
 * no `catch (e: Exception)` on the way up stops from taking the app down.
 */
object BitmapSampling {

    /**
     * The `BitmapFactory.Options.inSampleSize` for a [width]×[height] image that
     * must still cover [reqWidth]×[reqHeight]: the largest power of two that
     * keeps the image's short side at or above the target's short side and its
     * long side at or above the target's long side.
     *
     * Orientation-blind on purpose. The target comes from the display metrics,
     * which flip when the phone is held sideways, and a portrait wallpaper set
     * from a sideways phone still has to fill the portrait screen it ends up
     * on. The price is that a landscape image bound for a portrait screen can
     * be sampled further than that screen needs. The app's own images never get
     * near that: the wallpaper is a 9:16 portrait capture, and the glass widget
     * strips are smaller than the screen.
     *
     * Any dimension that is unknown (zero or negative) means "do not sample".
     */
    fun inSampleSize(width: Int, height: Int, reqWidth: Int, reqHeight: Int): Int {
        if (width <= 0 || height <= 0 || reqWidth <= 0 || reqHeight <= 0) return 1
        val srcShort = minOf(width, height)
        val srcLong = maxOf(width, height)
        val reqShort = minOf(reqWidth, reqHeight)
        val reqLong = maxOf(reqWidth, reqHeight)
        var sample = 1
        while (srcShort / (sample * 2) >= reqShort && srcLong / (sample * 2) >= reqLong) {
            sample *= 2
        }
        return sample
    }
}
