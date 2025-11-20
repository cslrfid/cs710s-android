import Flutter
import UIKit
import CSL_CS710S_Library

/// Flutter plugin for RFID platform channel registration
public class RfidPlugin: NSObject, FlutterPlugin {
    private var rfidPlatformChannel: RfidPlatformChannel?
    private var permissionChannel: PermissionChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = RfidPlugin()

        // Register RFID platform channel
        instance.rfidPlatformChannel = RfidPlatformChannel()
        instance.rfidPlatformChannel?.register(with: registrar.messenger())

        // Register permission channel
        instance.permissionChannel = PermissionChannel()
        instance.permissionChannel?.register(with: registrar.messenger())
    }
}
