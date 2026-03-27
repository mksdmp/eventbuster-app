package com.example.eventbuster

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eventbuster/mail_launcher"
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
            "eventbuster/map_launcher"
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
    }
}
