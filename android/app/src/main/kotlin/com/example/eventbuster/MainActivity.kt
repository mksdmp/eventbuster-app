package com.example.eventbuster

import android.app.DownloadManager
import android.content.Intent
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val MAIL_CHANNEL = "eventbuster/mail_launcher"
        private const val MAP_CHANNEL = "eventbuster/map_launcher"
        private const val PDF_DOWNLOAD_CHANNEL = "eventbuster/pdf_download"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAIL_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "launchMailto") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val email = call.argument<String>("email")?.trim().orEmpty()
            if (email.isEmpty()) {
                result.success(false)
                return@setMethodCallHandler
            }

            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("mailto:$email")
            }

            if (intent.resolveActivity(packageManager) == null) {
                result.success(false)
                return@setMethodCallHandler
            }

            startActivity(intent)
            result.success(true)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAP_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "openUrl") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")?.trim().orEmpty()
            if (url.isEmpty()) {
                result.success(false)
                return@setMethodCallHandler
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(url)
            }

            if (intent.resolveActivity(packageManager) == null) {
                result.success(false)
                return@setMethodCallHandler
            }

            startActivity(intent)
            result.success(true)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PDF_DOWNLOAD_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "enqueuePdfDownload") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")?.trim().orEmpty()
            if (url.isEmpty()) {
                result.error("invalid_url", "Missing PDF download URL.", null)
                return@setMethodCallHandler
            }

            val fileName = normalizeFileName(call.argument<String>("fileName"))
            val rawHeaders = call.argument<Map<*, *>>("headers").orEmpty()
            val headers = rawHeaders.entries.mapNotNull { entry ->
                val key = entry.key?.toString()?.trim().orEmpty()
                val value = entry.value?.toString()?.trim().orEmpty()
                if (key.isEmpty() || value.isEmpty()) {
                    null
                } else {
                    key to value
                }
            }

            try {
                val request = DownloadManager.Request(Uri.parse(url)).apply {
                    setTitle(fileName)
                    setDescription("Downloading ticket PDF")
                    setMimeType("application/pdf")
                    setNotificationVisibility(
                        DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                    )
                    setDestinationInExternalPublicDir(
                        Environment.DIRECTORY_DOWNLOADS,
                        fileName
                    )
                    setAllowedOverMetered(true)
                    setAllowedOverRoaming(true)
                    headers.forEach { (key, value) ->
                        addRequestHeader(key, value)
                    }
                }

                val downloadManager =
                    getSystemService(DOWNLOAD_SERVICE) as DownloadManager
                downloadManager.enqueue(request)

                result.success(
                    "Download started. Check the notification shade or Downloads folder."
                )
            } catch (error: Exception) {
                result.error(
                    "download_failed",
                    error.message ?: "Unable to start PDF download.",
                    null
                )
            }
        }
    }

    private fun normalizeFileName(fileName: String?): String {
        val trimmed = fileName?.trim().orEmpty()
        val sanitized = trimmed
            .replace(Regex("[<>:\"/\\\\|?*]"), "_")
            .replace(Regex("\\s+"), "_")

        if (sanitized.isEmpty()) {
            return "ticket.pdf"
        }

        return if (sanitized.lowercase().endsWith(".pdf")) {
            sanitized
        } else {
            "$sanitized.pdf"
        }
    }
}
