import 'dart:async';
import '../models/rfid_reader.dart';
import '../models/rfid_error.dart';
import 'rfid_service.dart';

/// Service for managing RFID reader scanning
class ScanService {
  final RfidService _rfidService;

  final _readersController = StreamController<List<RfidReader>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _errorController = StreamController<RfidError>.broadcast();

  StreamSubscription<ScanEvent>? _scanEventSubscription;

  final List<RfidReader> _discoveredReaders = [];
  bool _isScanning = false;

  ScanService(this._rfidService);

  /// Stream of discovered readers (cumulative list)
  Stream<List<RfidReader>> get readers => _readersController.stream;

  /// Stream of scanning state
  Stream<bool> get isScanning => _scanningController.stream;

  /// Stream of scan errors
  Stream<RfidError> get errors => _errorController.stream;

  /// Get current list of discovered readers
  List<RfidReader> get discoveredReaders => List.unmodifiable(_discoveredReaders);

  /// Get current scanning state
  bool get scanning => _isScanning;

  /// Initialize service - start listening to scan events
  void initialize() {
    _scanEventSubscription = _rfidService.scanEvents.listen(
      _handleScanEvent,
      onError: (error) {
        _errorController.add(RfidError(
          message: 'Scan event stream error: $error',
          type: RfidErrorType.unknown,
        ));
      },
    );
  }

  /// Start scanning for RFID readers
  Future<void> startScan() async {
    try {
      // Clear previous results
      _discoveredReaders.clear();
      _readersController.add(List.from(_discoveredReaders));

      await _rfidService.startScan();
      _isScanning = true;
      _scanningController.add(true);
    } catch (e) {
      _isScanning = false;
      _scanningController.add(false);
      _errorController.add(RfidError(
        message: 'Failed to start scan',
        type: RfidErrorType.scanFailed,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Stop scanning for RFID readers
  Future<void> stopScan() async {
    try {
      await _rfidService.stopScan();
      _isScanning = false;
      _scanningController.add(false);
    } catch (e) {
      _errorController.add(RfidError(
        message: 'Failed to stop scan',
        type: RfidErrorType.scanFailed,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Clear discovered readers list
  void clearReaders() {
    _discoveredReaders.clear();
    _readersController.add(List.from(_discoveredReaders));
  }

  /// Handle scan events from RfidService
  void _handleScanEvent(ScanEvent event) {
    switch (event) {
      case ReaderDiscoveredEvent():
        _handleReaderDiscovered(event.reader);
      case ScanErrorEvent():
        _handleScanError(event.error);
    }
  }

  /// Handle reader discovered event
  void _handleReaderDiscovered(RfidReader reader) {
    // Check if reader already exists (by address)
    final existingIndex = _discoveredReaders.indexWhere(
      (r) => r.address == reader.address,
    );

    if (existingIndex != -1) {
      // Update existing reader (RSSI may have changed)
      _discoveredReaders[existingIndex] = reader;
    } else {
      // Add new reader
      _discoveredReaders.add(reader);
    }

    // Sort by RSSI (strongest signal first)
    _discoveredReaders.sort((a, b) => b.rssi.compareTo(a.rssi));

    // Emit updated list
    _readersController.add(List.from(_discoveredReaders));
  }

  /// Handle scan error event
  void _handleScanError(RfidError error) {
    _isScanning = false;
    _scanningController.add(false);
    _errorController.add(error);
  }

  /// Dispose resources
  void dispose() {
    _scanEventSubscription?.cancel();
    _readersController.close();
    _scanningController.close();
    _errorController.close();
  }
}
