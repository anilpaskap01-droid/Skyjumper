package com.onpa.auto_apk_hub

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "auto_apk_hub/native"
    private val pickApkRequest = 7201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallPackages" -> {
                        val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            packageManager.canRequestPackageInstalls()
                        } else true
                        result.success(allowed)
                    }
                    "openUnknownSources" -> {
                        openUnknownSourcesSettings()
                        result.success(true)
                    }
                    "installDownloadedApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("BAD_PATH", "APK yolu eksik.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installDownloadedApk(path)
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("INSTALL_FAILED", t.message ?: "Paket yükleyici açılamadı.", null)
                        }
                    }
                    "pickAndInstallApk" -> {
                        try {
                            pickLocalApk()
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("PICK_FAILED", t.message ?: "APK seçici açılamadı.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openUnknownSourcesSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName")
                )
            )
        }
    }

    private fun installDownloadedApk(path: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()) {
            openUnknownSourcesSettings()
            return
        }
        val file = File(path)
        require(file.exists() && file.isFile) { "APK dosyası bulunamadı." }
        installFile(file)
    }

    private fun installFile(file: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun pickLocalApk() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()) {
            openUnknownSourcesSettings()
            return
        }

        // Samsung My Files ve bazı dosya sağlayıcıları APK MIME tipini doğru bildirmediği için
        // */* kullanıyoruz. Seçimden sonra dosya adını/başlığını kontrol edip kendi cache'imize
        // kopyalıyoruz; böylece package installer URI uyumsuzlukları da ortadan kalkıyor.
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                "application/vnd.android.package-archive",
                "application/octet-stream",
                "application/zip"
            ))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(Intent.createChooser(intent, "APK dosyası seç"), pickApkRequest)
    }

    @Deprecated("Deprecated in Android API; retained for broad Flutter compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickApkRequest || resultCode != RESULT_OK) return

        val uri = data?.data ?: return
        try {
            val displayName = queryDisplayName(uri)
            val mime = contentResolver.getType(uri).orEmpty()
            val looksLikeApk = displayName.lowercase().endsWith(".apk") ||
                mime == "application/vnd.android.package-archive" ||
                mime == "application/octet-stream" || mime == "application/zip"

            if (!looksLikeApk) {
                android.widget.Toast.makeText(this, "APK dosyası seçmelisin.", android.widget.Toast.LENGTH_LONG).show()
                return
            }

            val target = File(cacheDir, "selected_${System.currentTimeMillis()}.apk")
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Seçilen dosya açılamadı." }
                FileOutputStream(target).use { output -> input.copyTo(output, 64 * 1024) }
            }

            require(target.length() > 4) { "Seçilen APK boş veya geçersiz." }
            installFile(target)
        } catch (t: Throwable) {
            android.widget.Toast.makeText(
                this,
                t.message ?: "APK açılamadı.",
                android.widget.Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun queryDisplayName(uri: Uri): String {
        return try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0) ?: "selected.apk" else "selected.apk"
            } ?: "selected.apk"
        } catch (_: Throwable) {
            "selected.apk"
        }
    }
}
