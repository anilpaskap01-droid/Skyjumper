package com.onpa.auto_apk_hub

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipInputStream

class MainActivity : FlutterActivity() {
    private val channelName = "auto_apk_hub/native"
    private val pickApkRequest = 7201
    private var pendingPickAfterPermission = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallPackages" -> result.success(canInstallPackages())
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
                            if (!canInstallPackages()) {
                                pendingPickAfterPermission = true
                                openUnknownSourcesSettings()
                            } else {
                                pickLocalApk()
                            }
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("PICK_FAILED", t.message ?: "APK seçici açılamadı.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        if (pendingPickAfterPermission && canInstallPackages()) {
            pendingPickAfterPermission = false
            window.decorView.postDelayed({
                try { pickLocalApk() } catch (_: Throwable) {}
            }, 350)
        }
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else true
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
        if (!canInstallPackages()) {
            openUnknownSourcesSettings()
            return
        }
        val file = File(path)
        require(file.exists() && file.isFile) { "APK dosyası bulunamadı." }
        installFile(normalizeInstallableFile(file))
    }

    private fun installFile(file: File) {
        require(packageManager.getPackageArchiveInfo(file.absolutePath, 0) != null) {
            "Seçilen dosya Android tarafından geçerli APK olarak tanınmadı."
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        launchPackageInstaller(uri)
    }

    private fun normalizeInstallableFile(source: File): File {
        // APK uzantısı Android PackageManager için önemlidir. Kaynak farklı uzantıdaysa
        // önce aynı baytları .apk adlı güvenli cache dosyasına kopyalayıp gerçek APK mı bak.
        val directCandidate = if (source.name.lowercase().endsWith(".apk")) {
            source
        } else {
            File(cacheDir, "candidate_${System.currentTimeMillis()}.apk").also { candidate ->
                source.inputStream().use { input ->
                    FileOutputStream(candidate).use { output -> input.copyTo(output, 64 * 1024) }
                }
            }
        }

        if (packageManager.getPackageArchiveInfo(directCandidate.absolutePath, 0) != null) {
            return directCandidate
        }

        val extracted = File(cacheDir, "extracted_${System.currentTimeMillis()}.apk")
        if (extracted.exists()) extracted.delete()

        try {
            ZipInputStream(source.inputStream().buffered()).use { zip ->
                var entry = zip.nextEntry
                while (entry != null) {
                    val safeName = entry.name.replace('\\', '/')
                    if (!entry.isDirectory && safeName.lowercase().endsWith(".apk")) {
                        FileOutputStream(extracted).use { output ->
                            val buffer = ByteArray(64 * 1024)
                            var total = 0L
                            while (true) {
                                val count = zip.read(buffer)
                                if (count <= 0) break
                                total += count
                                require(total <= 800L * 1024L * 1024L) {
                                    "ZIP içindeki APK 800 MB sınırından büyük."
                                }
                                output.write(buffer, 0, count)
                            }
                        }
                        zip.closeEntry()
                        break
                    }
                    zip.closeEntry()
                    entry = zip.nextEntry
                }
            }
        } catch (_: Throwable) {
            if (!extracted.exists()) {
                throw IllegalArgumentException("Seçilen dosya geçerli APK değil.")
            }
        }

        require(extracted.exists() && extracted.length() > 4) {
            "Bu dosya APK değil ve ZIP içinde .apk bulunamadı."
        }
        require(packageManager.getPackageArchiveInfo(extracted.absolutePath, 0) != null) {
            "ZIP içindeki dosya geçerli bir Android APK'sı değil."
        }
        return extracted
    }

    private fun launchPackageInstaller(uri: Uri) {
        val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            data = uri
            clipData = ClipData.newRawUri("APK", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, false)
            putExtra(Intent.EXTRA_RETURN_RESULT, false)
        }

        val resolved = packageManager.resolveActivity(installIntent, 0)
        if (resolved != null) {
            grantUriPermission(
                resolved.activityInfo.packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            startActivity(installIntent)
            return
        }

        val fallback = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            clipData = ClipData.newRawUri("APK", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(fallback)
    }

    private fun pickLocalApk() {
        if (!canInstallPackages()) {
            pendingPickAfterPermission = true
            openUnknownSourcesSettings()
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "application/vnd.android.package-archive",
                    "application/octet-stream",
                    "application/zip",
                    "*/*"
                )
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(Intent.createChooser(intent, "APK veya APK içeren ZIP seç"), pickApkRequest)
    }

    @Deprecated("Deprecated in Android API; retained for broad Flutter compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickApkRequest || resultCode != RESULT_OK) return

        val uri = data?.data ?: return
        try {
            val displayName = queryDisplayName(uri)
            val lowerName = displayName.lowercase()
            val mime = contentResolver.getType(uri).orEmpty()
            val supported = lowerName.endsWith(".apk") || lowerName.endsWith(".zip") ||
                mime == "application/vnd.android.package-archive" ||
                mime == "application/octet-stream" || mime == "application/zip"

            if (!supported) {
                Toast.makeText(this, "APK veya APK içeren ZIP seçmelisin.", Toast.LENGTH_LONG).show()
                return
            }

            val suffix = if (lowerName.endsWith(".zip")) ".zip" else ".apk"
            val source = File(cacheDir, "selected_${System.currentTimeMillis()}$suffix")
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Seçilen dosya açılamadı." }
                FileOutputStream(source).use { output ->
                    val buffer = ByteArray(64 * 1024)
                    var total = 0L
                    while (true) {
                        val count = input.read(buffer)
                        if (count <= 0) break
                        total += count
                        require(total <= 900L * 1024L * 1024L) {
                            "Seçilen dosya 900 MB sınırından büyük."
                        }
                        output.write(buffer, 0, count)
                    }
                }
            }

            require(source.length() > 4) { "Seçilen dosya boş veya geçersiz." }
            installFile(normalizeInstallableFile(source))
        } catch (t: Throwable) {
            Toast.makeText(this, t.message ?: "APK açılamadı.", Toast.LENGTH_LONG).show()
        }
    }

    private fun queryDisplayName(uri: Uri): String {
        return try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { c ->
                if (c.moveToFirst()) c.getString(0) ?: "selected.apk" else "selected.apk"
            } ?: "selected.apk"
        } catch (_: Throwable) {
            "selected.apk"
        }
    }
}
