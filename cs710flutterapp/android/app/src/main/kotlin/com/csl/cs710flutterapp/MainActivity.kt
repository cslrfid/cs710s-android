package com.csl.cs710flutterapp

import android.os.Bundle
import com.csl.rfidsdk.RfidManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main Flutter activity for CS710 Flutter App
 * Integrates with csl-rfid-android-sdk via platform channels
 */
class MainActivity : FlutterActivity() {
    private lateinit var platformChannel: RfidPlatformChannel
    private lateinit var rfidManager: RfidManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Create RfidManager instance for this app
        rfidManager = RfidManager.create(this)

        // Initialize platform channel bridge
        platformChannel = RfidPlatformChannel(
            this,
            rfidManager,
            flutterEngine.dartExecutor.binaryMessenger
        )
        platformChannel.initialize()
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release RFID resources
        rfidManager.release()
    }
}
