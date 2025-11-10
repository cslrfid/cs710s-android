package com.csl.cs710flutterapp

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.csl.rfidsdk.RfidManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Flutter activity for CS710 Flutter App
 * Integrates with csl-rfid-android-sdk via platform channels
 */
class MainActivity : FlutterActivity() {
    private lateinit var platformChannel: RfidPlatformChannel
    private lateinit var rfidManager: RfidManager
    private lateinit var permissionChannel: MethodChannel

    private var permissionResult: MethodChannel.Result? = null

    companion object {
        private const val PERMISSION_CHANNEL = "com.csl.rfid/permissions"
        private const val PERMISSION_REQUEST_CODE = 100
    }

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

        // Setup permission channel
        permissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
        permissionChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    result.success(hasRequiredPermissions())
                }
                "requestPermissions" -> {
                    if (hasRequiredPermissions()) {
                        result.success(true)
                    } else {
                        permissionResult = result
                        requestPermissions()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            // Android 11 and below
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ),
                PERMISSION_REQUEST_CODE
            )
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.BLUETOOTH,
                    Manifest.permission.BLUETOOTH_ADMIN
                ),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResult?.success(allGranted)
            permissionResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release RFID resources
        rfidManager.release()
    }
}
