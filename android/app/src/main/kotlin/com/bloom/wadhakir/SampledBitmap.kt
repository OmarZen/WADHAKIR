package com.bloom.wadhakir

import android.graphics.Bitmap
import android.graphics.BitmapFactory

/**
 * Every bitmap this app decodes from a file goes through here.
 *
 * Two passes: the first reads only the header (`inJustDecodeBounds`, no pixels
 * allocated), the second decodes at the [BitmapSampling.inSampleSize] that size
 * implies. A bare `BitmapFactory.decodeFile(path)` decodes at whatever size the
 * file happens to be, which Play Console flags as missing downsampling.
 */
object SampledBitmap {

    /**
     * Decodes [path] no larger than it needs to be to cover
     * [reqWidth]×[reqHeight], or returns null when the file is not an image
     * BitmapFactory can read.
     */
    fun decodeFile(path: String, reqWidth: Int, reqHeight: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val options = BitmapFactory.Options().apply {
            inSampleSize = BitmapSampling.inSampleSize(
                bounds.outWidth,
                bounds.outHeight,
                reqWidth,
                reqHeight,
            )
        }
        return BitmapFactory.decodeFile(path, options)
    }
}
