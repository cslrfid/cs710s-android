import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register generated plugins
        GeneratedPluginRegistrant.register(with: self)

        // Register RFID plugin using FlutterPluginRegistry
        RfidPlugin.register(with: self.registrar(forPlugin: "RfidPlugin")!)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
