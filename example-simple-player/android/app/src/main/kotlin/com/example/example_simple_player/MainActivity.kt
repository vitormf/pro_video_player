package com.example.example_simple_player

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var fileChannel: MethodChannel? = null
    private var pendingFile: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        fileChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "simple_player/file")
        fileChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> {
                    result.success(pendingFile)
                    pendingFile = null
                }
                else -> result.notImplemented()
            }
        }

        // Handle intent if app was started with a file/URL
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        }

        uri?.let { fileUri ->
            val uriString = fileUri.toString()

            if (fileChannel != null) {
                // Flutter is ready - send directly
                fileChannel?.invokeMethod("openFile", uriString)
            } else {
                // Flutter not ready yet - save for later
                pendingFile = uriString
            }
        }
    }
}
