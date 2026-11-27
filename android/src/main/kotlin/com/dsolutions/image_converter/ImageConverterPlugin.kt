package com.dsolutions.image_converter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.min
import kotlin.math.roundToInt

/** ImageConverterPlugin: image <-> PDF conversion using Android's built-in PDF APIs. */
class ImageConverterPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private val executor: ExecutorService = Executors.newSingleThreadExecutor()
  private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

  private class ConversionException(val code: String, message: String) : Exception(message)

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "image_converter")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val task: () -> Any = when (call.method) {
      "imagesToPdf" -> { { imagesToPdf(call) } }
      "pdfToImages" -> { { pdfToImages(call) } }
      "pdfPageCount" -> { { pdfPageCount(call) } }
      else -> {
        result.notImplemented()
        return
      }
    }
    executor.execute {
      try {
        val value = task()
        mainHandler.post { result.success(value) }
      } catch (e: ConversionException) {
        mainHandler.post { result.error(e.code, e.message, null) }
      } catch (e: OutOfMemoryError) {
        mainHandler.post { result.error("CONVERSION_FAILED", "Out of memory: ${e.message}", null) }
      } catch (e: Exception) {
        mainHandler.post { result.error("CONVERSION_FAILED", e.message ?: e.toString(), null) }
      }
    }
  }

  // ---------------------------------------------------------------- image -> pdf

  private fun imagesToPdf(call: MethodCall): ByteArray {
    val images = call.argument<List<ByteArray>>("images")
      ?: throw ConversionException("INVALID_ARGUMENT", "images is required")
    val pageSize = call.argument<Map<String, Double>>("pageSize")
    val margin = (call.argument<Number>("margin") ?: 0).toFloat()

    val document = PdfDocument()
    try {
      images.forEachIndexed { index, bytes ->
        val bitmap = decodeImage(bytes)
          ?: throw ConversionException("INVALID_IMAGE", "Image at index $index could not be decoded")
        try {
          val pageW: Int
          val pageH: Int
          val dest: RectF
          if (pageSize == null) {
            pageW = bitmap.width
            pageH = bitmap.height
            dest = RectF(0f, 0f, pageW.toFloat(), pageH.toFloat())
          } else {
            pageW = pageSize.getValue("width").roundToInt()
            pageH = pageSize.getValue("height").roundToInt()
            val boxW = pageW - 2 * margin
            val boxH = pageH - 2 * margin
            val scale = min(boxW / bitmap.width, boxH / bitmap.height)
            val w = bitmap.width * scale
            val h = bitmap.height * scale
            val left = (pageW - w) / 2f
            val top = (pageH - h) / 2f
            dest = RectF(left, top, left + w, top + h)
          }
          val page = document.startPage(PdfDocument.PageInfo.Builder(pageW, pageH, index + 1).create())
          page.canvas.drawBitmap(bitmap, null, dest, Paint(Paint.FILTER_BITMAP_FLAG))
          document.finishPage(page)
        } finally {
          bitmap.recycle()
        }
      }
      val out = ByteArrayOutputStream()
      document.writeTo(out)
      return out.toByteArray()
    } finally {
      document.close()
    }
  }

  /** Decodes [bytes] and applies EXIF orientation. */
  private fun decodeImage(bytes: ByteArray): Bitmap? {
    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
    val orientation = try {
      ExifInterface(ByteArrayInputStream(bytes))
        .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    } catch (e: IOException) {
      ExifInterface.ORIENTATION_NORMAL
    }
    val matrix = Matrix()
    when (orientation) {
      ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
      ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
      ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
      ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
      ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
      ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
      ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
      else -> return bitmap
    }
    val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    if (rotated !== bitmap) bitmap.recycle()
    return rotated
  }

  // ---------------------------------------------------------------- pdf -> image

  private fun pdfToImages(call: MethodCall): List<ByteArray> {
    val pdf = call.argument<ByteArray>("pdf")
      ?: throw ConversionException("INVALID_ARGUMENT", "pdf is required")
    val dpi = (call.argument<Number>("dpi") ?: 144).toDouble()
    val jpeg = call.argument<String>("format") == "jpeg"
    val quality = call.argument<Int>("quality") ?: 90
    val requested = call.argument<List<Int>>("pages")

    return withRenderer(pdf) { renderer ->
      val indexes = requested ?: (0 until renderer.pageCount).toList()
      indexes.forEach {
        if (it < 0 || it >= renderer.pageCount) {
          throw ConversionException(
            "INVALID_PAGE", "Page index $it is out of range (document has ${renderer.pageCount} pages)"
          )
        }
      }
      val scale = dpi / 72.0
      indexes.map { index ->
        renderer.openPage(index).use { page ->
          val w = (page.width * scale).roundToInt().coerceAtLeast(1)
          val h = (page.height * scale).roundToInt().coerceAtLeast(1)
          if (w.toLong() * h > MAX_PIXELS) {
            throw ConversionException("INVALID_ARGUMENT", "Page $index at $dpi dpi is too large (${w}x$h)")
          }
          val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
          try {
            bitmap.eraseColor(Color.WHITE)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            val out = ByteArrayOutputStream()
            bitmap.compress(
              if (jpeg) Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG,
              quality,
              out,
            )
            out.toByteArray()
          } finally {
            bitmap.recycle()
          }
        }
      }
    }
  }

  private fun pdfPageCount(call: MethodCall): Int {
    val pdf = call.argument<ByteArray>("pdf")
      ?: throw ConversionException("INVALID_ARGUMENT", "pdf is required")
    return withRenderer(pdf) { it.pageCount }
  }

  /** PdfRenderer needs a seekable file descriptor, so the bytes go through a temp file. */
  private fun <T> withRenderer(pdf: ByteArray, block: (PdfRenderer) -> T): T {
    val file = File.createTempFile("image_converter_", ".pdf", context.cacheDir)
    try {
      file.writeBytes(pdf)
      val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
      val renderer = try {
        PdfRenderer(fd)
      } catch (e: SecurityException) {
        fd.close()
        throw ConversionException("PDF_ENCRYPTED", "PDF is password protected")
      } catch (e: IOException) {
        fd.close()
        throw ConversionException("INVALID_PDF", "Not a valid PDF: ${e.message}")
      }
      return renderer.use(block) // closing the renderer also closes fd
    } finally {
      file.delete()
    }
  }

  private companion object {
    /** ~ 10000 x 10000 px; beyond this a single ARGB bitmap needs > 400 MB. */
    const val MAX_PIXELS = 100_000_000L
  }
}
