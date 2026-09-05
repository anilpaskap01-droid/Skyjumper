package com.onpa.auto_mirror_parked

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class ScreenCaptureService : Service() {
    companion object {
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        private const val CHANNEL_ID = "auto_mirror_capture"
        private const val NOTIFICATION_ID = 22041
    }

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var workerThread: HandlerThread? = null
    private var workerHandler: Handler? = null
    private var lastFrameAt = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()

        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        val resultData = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent?.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra(EXTRA_RESULT_DATA)
        }

        if (resultCode == 0 || resultData == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        stopProjection()
        startProjection(resultCode, resultData)
        return START_NOT_STICKY
    }

    private fun startAsForeground() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentTitle("AutoMirror Parked")
            .setContentText("Telefon ekranı paylaşımı açık")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startProjection(resultCode: Int, resultData: Intent) {
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val p = manager.getMediaProjection(resultCode, resultData) ?: run {
            FrameStore.clear()
            stopSelf()
            return
        }
        projection = p

        workerThread = HandlerThread("AutoMirrorCapture").also { it.start() }
        workerHandler = Handler(workerThread!!.looper)

        val metrics = resources.displayMetrics
        val sourceW = max(1, metrics.widthPixels)
        val sourceH = max(1, metrics.heightPixels)
        val density = max(1, metrics.densityDpi)

        val maxW = 1280
        val maxH = 720
        val scale = min(1.0, min(maxW.toDouble() / sourceW, maxH.toDouble() / sourceH))
        val width = max(2, (sourceW * scale).roundToInt() and 0xFFFFFFFE.toInt())
        val height = max(2, (sourceH * scale).roundToInt() and 0xFFFFFFFE.toInt())

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        p.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stopProjection()
                stopSelf()
            }
        }, workerHandler)

        imageReader!!.setOnImageAvailableListener({ reader ->
            val now = SystemClock.elapsedRealtime()
            if (now - lastFrameAt < 110) {
                reader.acquireLatestImage()?.close()
                return@setOnImageAvailableListener
            }
            lastFrameAt = now

            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            try {
                val plane = image.planes.firstOrNull() ?: return@setOnImageAvailableListener
                val buffer = plane.buffer
                val pixelStride = plane.pixelStride
                val rowStride = plane.rowStride
                val rowPadding = rowStride - pixelStride * width
                val paddedWidth = width + rowPadding / pixelStride

                val padded = Bitmap.createBitmap(paddedWidth, height, Bitmap.Config.ARGB_8888)
                padded.copyPixelsFromBuffer(buffer)
                val cropped = if (paddedWidth == width) padded else Bitmap.createBitmap(padded, 0, 0, width, height)

                val out = java.io.ByteArrayOutputStream()
                cropped.compress(Bitmap.CompressFormat.JPEG, 68, out)
                FrameStore.latestFrame = out.toByteArray()
                FrameStore.running = true

                if (cropped !== padded) cropped.recycle()
                padded.recycle()
            } catch (_: Throwable) {
            } finally {
                image.close()
            }
        }, workerHandler)

        virtualDisplay = p.createVirtualDisplay(
            "AutoMirrorParkedDisplay",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader!!.surface,
            null,
            workerHandler
        )
        FrameStore.running = true
    }

    private fun stopProjection() {
        FrameStore.running = false
        try { imageReader?.setOnImageAvailableListener(null, null) } catch (_: Throwable) {}
        try { virtualDisplay?.release() } catch (_: Throwable) {}
        virtualDisplay = null
        try { imageReader?.close() } catch (_: Throwable) {}
        imageReader = null
        val p = projection
        projection = null
        try { p?.stop() } catch (_: Throwable) {}
        try { workerThread?.quitSafely() } catch (_: Throwable) {}
        workerThread = null
        workerHandler = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AutoMirror ekran paylaşımı",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopProjection()
        FrameStore.clear()
        super.onDestroy()
    }
}
