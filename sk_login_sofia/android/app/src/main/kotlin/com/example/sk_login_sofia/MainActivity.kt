package com.example.sk_login_sofia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.media.MediaPlayer;


class MainActivity: FlutterActivity() {

    private val AUDIO_METHOD_CHANNEL = "audio_service"

override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_METHOD_CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "beep" -> {
                    val mediaPlayer = MediaPlayer.create(this@MainActivity, R.raw.beep)
                    mediaPlayer.start()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
}

}
