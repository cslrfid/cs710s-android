import Flutter
import UIKit
import CSL_CS710S_Library

/// Flutter plugin for RFID platform channel registration
public class RfidPlugin: NSObject, FlutterPlugin {
    private var rfidPlatformChannel: RfidPlatformChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = RfidPlugin()
        instance.rfidPlatformChannel = RfidPlatformChannel()
        instance.rfidPlatformChannel?.register(with: registrar.messenger())
    }
}
