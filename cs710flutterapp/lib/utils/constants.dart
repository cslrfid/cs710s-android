class AppConstants {
  // Platform channel names
  static const String methodChannel = 'com.csl.rfid/manager';
  static const String scanEventsChannel = 'com.csl.rfid/scan_events';
  static const String connectionEventsChannel = 'com.csl.rfid/connection_events';
  static const String inventoryEventsChannel = 'com.csl.rfid/inventory_events';
  static const String geigerEventsChannel = 'com.csl.rfid/geiger_events';
  static const String barcodeEventsChannel = 'com.csl.rfid/barcode_events';
  static const String batteryEventsChannel = 'com.csl.rfid/battery_events';
  static const String triggerEventsChannel = 'com.csl.rfid/trigger_events';
  static const String configEventsChannel = 'com.csl.rfid/config_events';

  // Reader configuration defaults
  static const int defaultPowerLevel = 300; // 30.0 dBm
  static const int defaultSession = 1;
  static const int defaultQValue = 7;
  static const String defaultTarget = 'A';
  static const String defaultInventoryMode = 'COMPACT';
  static const String defaultRegion = 'FCC';

  // UI constants
  static const int batteryPollIntervalSeconds = 5;
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration connectionTimeout = Duration(seconds: 35);
}
