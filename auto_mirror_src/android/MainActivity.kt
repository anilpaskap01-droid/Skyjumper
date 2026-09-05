package com.onpa.auto_mirror_parked

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.view.Display
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "auto_mirror/native"
    private val captureRequest = 9101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isExternalDisplay" -> result.success(isExternalDisplay())
                    "captureRunning" -> result.success(FrameStore.running)
                    "getFrame" -> result.success(FrameStore.latestFrame)
                    "startCapture" -> {
                        try {
                            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                            startActivityForResult(manager.createScreenCaptureIntent(), captureRequest)
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("CAPTURE_START", t.message ?: "Ekran paylaşım izni açılamadı.", null)
                        }
                    }
                    "stopCapture" -> {
                        stopService(Intent(this, ScreenCaptureService::class.java))
                        FrameStore.clear()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isExternalDisplay(): Boolean {
        val id = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.displayId ?: Display.DEFAULT_DISPLAY
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.displayId
        }
        return id != Display.DEFAULT_DISPLAY
    }

    @Deprecated("Deprecated Android callback retained for Flutter compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != captureRequest) return
        if (resultCode != Activity.RESULT_OK || data == null) return

        val service = Intent(this, ScreenCaptureService::class.java).apply {
            putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ScreenCaptureService.EXTRA_RESULT_DATA, data)
        }
        ContextCompat.startForegroundService(this, service)
    }
}

object FrameStore {
    @Volatile var latestFrame: ByteArray? = null
    @Volatile var running: Boolean = false

    fun clear() {
        latestFrame = null
        running = false
    }
}
