import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _decimalFormat = NumberFormat('0.0');
  static final NumberFormat _integerFormat = NumberFormat('0');
  static final NumberFormat _rateFormat = NumberFormat('0.00');

  /// Format RSSI value (e.g., "-50.0 dBm")
  static String formatRssi(double rssi) {
    return '${_decimalFormat.format(rssi)} dBm';
  }

  /// Format battery level (e.g., "85%")
  static String formatBatteryLevel(int level) {
    return '$level%';
  }

  /// Format battery with charging status (e.g., "85% (Charging)")
  static String formatBattery(int level, bool charging) {
    final base = formatBatteryLevel(level);
    return charging ? '$base (Charging)' : base;
  }

  /// Format read count (e.g., "1,234")
  static String formatCount(int count) {
    return _integerFormat.format(count);
  }

  /// Format read rate (e.g., "123.45 tags/s")
  static String formatReadRate(double rate) {
    return '${_rateFormat.format(rate)} tags/s';
  }

  /// Format proximity percentage (e.g., "75%")
  static String formatProximity(int proximity) {
    return '$proximity%';
  }

  /// Format elapsed time in seconds (e.g., "1:23")
  static String formatElapsedTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format EPC (insert spaces every 4 chars for readability)
  static String formatEpc(String epc) {
    if (epc.length <= 4) return epc;

    final buffer = StringBuffer();
    for (int i = 0; i < epc.length; i += 4) {
      if (i > 0) buffer.write(' ');
      final end = (i + 4 < epc.length) ? i + 4 : epc.length;
      buffer.write(epc.substring(i, end));
    }
    return buffer.toString();
  }

  /// Format timestamp to readable time string
  static String formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final timeFormat = DateFormat('HH:mm:ss');
    return timeFormat.format(dateTime);
  }
}
