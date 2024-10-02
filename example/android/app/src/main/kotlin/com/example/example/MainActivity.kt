package com.example.example

import android.os.Bundle
import com.google.android.gms.cast.framework.CastContext
import fl.pip.FlPiPActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlPiPActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize CastContext in onCreate
        CastContext.getSharedInstance(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Register Flutter plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}