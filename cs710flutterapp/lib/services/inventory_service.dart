import 'dart:async';
import '../models/rfid_tag.dart';
import '../models/rfid_inventory_stats.dart';
import '../models/barcode_data.dart';
import '../models/barcode_stats.dart';
import '../models/rfid_error.dart';
import 'rfid_service.dart';

/// Service for managing RFID tag and barcode inventory operations
class InventoryService {
  final RfidService _rfidService;

  // RFID streams
  final _rfidTagsController = StreamController<List<RfidTag>>.broadcast();
  final _rfidStatsController = StreamController<RfidInventoryStats>.broadcast();
  final _rfidInventoryingController = StreamController<bool>.broadcast();
  final _rfidErrorController = StreamController<RfidError>.broadcast();

  // Barcode streams
  final _barcodesController = StreamController<List<BarcodeData>>.broadcast();
  final _barcodeStatsController = StreamController<BarcodeStats>.broadcast();
  final _barcodeScanningController = StreamController<bool>.broadcast();
  final _barcodeErrorController = StreamController<RfidError>.broadcast();

  StreamSubscription<InventoryEvent>? _inventoryEventSubscription;
  StreamSubscription<BarcodeEvent>? _barcodeEventSubscription;

  final Map<String, RfidTag> _tags = {}; // EPC -> Tag
  final List<BarcodeData> _barcodes = [];
  bool _isInventorying = false;
  bool _isBarcodeScanning = false;

  InventoryService(this._rfidService);

  // ========== RFID STREAMS ==========

  /// Stream of RFID tags (cumulative list, updated counts)
  Stream<List<RfidTag>> get rfidTags => _rfidTagsController.stream;

  /// Stream of RFID inventory statistics
  Stream<RfidInventoryStats> get rfidStats => _rfidStatsController.stream;

  /// Stream of RFID inventorying state
  Stream<bool> get isInventorying => _rfidInventoryingController.stream;

  /// Stream of RFID inventory errors
  Stream<RfidError> get rfidErrors => _rfidErrorController.stream;

  // ========== BARCODE STREAMS ==========

  /// Stream of barcodes (cumulative list)
  Stream<List<BarcodeData>> get barcodes => _barcodesController.stream;

  /// Stream of barcode statistics
  Stream<BarcodeStats> get barcodeStats => _barcodeStatsController.stream;

  /// Stream of barcode scanning state
  Stream<bool> get isBarcodeScanning => _barcodeScanningController.stream;

  /// Stream of barcode errors
  Stream<RfidError> get barcodeErrors => _barcodeErrorController.stream;

  // ========== GETTERS ==========

  /// Get current list of RFID tags
  List<RfidTag> get currentTags => _tags.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  /// Get current list of barcodes
  List<BarcodeData> get currentBarcodes => List.unmodifiable(_barcodes);

  /// Get current RFID inventorying state
  bool get inventorying => _isInventorying;

  /// Get current barcode scanning state
  bool get barcodeScanning => _isBarcodeScanning;

  /// Get unique tag count
  int get uniqueTagCount => _tags.length;

  /// Get total tag read count
  int get totalTagReads => _tags.values.fold(0, (sum, tag) => sum + tag.count);

  /// Get unique barcode count
  int get uniqueBarcodeCount => _barcodes.length;

  /// Initialize service - start listening to events
  void initialize() {
    _inventoryEventSubscription = _rfidService.inventoryEvents.listen(
      _handleInventoryEvent,
      onError: (error) {
        _rfidErrorController.add(RfidError(
          message: 'Inventory event stream error: $error',
          type: RfidErrorType.unknown,
        ));
      },
    );

    _barcodeEventSubscription = _rfidService.barcodeEvents.listen(
      _handleBarcodeEvent,
      onError: (error) {
        _barcodeErrorController.add(RfidError(
          message: 'Barcode event stream error: $error',
          type: RfidErrorType.unknown,
        ));
      },
    );
  }

  // ========== RFID METHODS ==========

  /// Start RFID tag inventory
  Future<void> startInventory() async {
    try {
      // Don't clear tags - allow cumulative scanning
      await _rfidService.startInventory();
      _isInventorying = true;
      _rfidInventoryingController.add(true);
    } catch (e) {
      _isInventorying = false;
      _rfidInventoryingController.add(false);
      _rfidErrorController.add(RfidError(
        message: 'Failed to start inventory',
        type: RfidErrorType.inventoryFailed,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Stop RFID tag inventory
  Future<void> stopInventory() async {
    try {
      await _rfidService.stopInventory();
      _isInventorying = false;
      _rfidInventoryingController.add(false);
    } catch (e) {
      _rfidErrorController.add(RfidError(
        message: 'Failed to stop inventory',
        type: RfidErrorType.inventoryFailed,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Clear RFID tags list
  void clearTags() {
    _tags.clear();
    _rfidTagsController.add([]);
  }

  /// Get tag by EPC
  RfidTag? getTagByEpc(String epc) {
    return _tags[epc];
  }

  // ========== BARCODE METHODS ==========

  /// Start barcode scanning
  Future<void> startBarcodeScan() async {
    try {
      await _rfidService.startBarcodeScan();
      _isBarcodeScanning = true;
      _barcodeScanningController.add(true);
    } catch (e) {
      _isBarcodeScanning = false;
      _barcodeScanningController.add(false);
      _barcodeErrorController.add(RfidError(
        message: 'Failed to start barcode scan',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Stop barcode scanning
  Future<void> stopBarcodeScan() async {
    try {
      await _rfidService.stopBarcodeScan();
      _isBarcodeScanning = false;
      _barcodeScanningController.add(false);
    } catch (e) {
      _barcodeErrorController.add(RfidError(
        message: 'Failed to stop barcode scan',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Clear barcodes list
  void clearBarcodes() {
    _barcodes.clear();
    _barcodesController.add([]);
  }

  // ========== EVENT HANDLERS ==========

  /// Handle inventory events from RfidService
  void _handleInventoryEvent(InventoryEvent event) {
    print('📱 InventoryService: Received inventory event: ${event.runtimeType}');
    switch (event) {
      case TagReadEvent():
        print('📱 InventoryService: TagReadEvent received - EPC: ${event.tag.epc}');
        _handleTagRead(event.tag);
      case InventoryRoundEvent():
        _handleInventoryRound(event.stats);
      case InventoryStoppedEvent():
        _handleInventoryStopped(event.stats);
      case InventoryErrorEvent():
        _handleInventoryError(event.error);
    }
  }

  /// Handle tag read event
  void _handleTagRead(RfidTag tag) {
    print('📱 InventoryService: _handleTagRead called for EPC: ${tag.epc}');
    final existingTag = _tags[tag.epc];

    if (existingTag != null) {
      // Update count for existing tag
      print('📱 InventoryService: Updating existing tag ${tag.epc}, old count: ${existingTag.count}, new count: ${existingTag.count + 1}');
      _tags[tag.epc] = existingTag.copyWith(
        count: existingTag.count + 1,
      );
    } else {
      // Add new tag
      print('📱 InventoryService: Adding new tag ${tag.epc}');
      _tags[tag.epc] = tag;
    }

    // Emit updated list (sorted by most recent read)
    final tagList = currentTags;
    print('📱 InventoryService: Emitting tag list with ${tagList.length} tags');
    _rfidTagsController.add(tagList);
    print('📱 InventoryService: Tag list emitted');
  }

  /// Handle inventory round update
  void _handleInventoryRound(RfidInventoryStats stats) {
    _rfidStatsController.add(stats);
  }

  /// Handle inventory stopped
  void _handleInventoryStopped(RfidInventoryStats stats) {
    _isInventorying = false;
    _rfidInventoryingController.add(false);
    _rfidStatsController.add(stats);
  }

  /// Handle inventory error
  void _handleInventoryError(RfidError error) {
    _isInventorying = false;
    _rfidInventoryingController.add(false);
    _rfidErrorController.add(error);
  }

  /// Handle barcode events from RfidService
  void _handleBarcodeEvent(BarcodeEvent event) {
    switch (event) {
      case BarcodeScannedEvent():
        _handleBarcodeScanned(event.barcode);
      case BarcodeStatsEvent():
        _handleBarcodeStats(event.stats);
      case BarcodeErrorEvent():
        _handleBarcodeError(event.error);
    }
  }

  /// Handle barcode scanned event
  void _handleBarcodeScanned(BarcodeData barcode) {
    // Check if barcode already exists
    final exists = _barcodes.any((b) => b.barcode == barcode.barcode);

    if (!exists) {
      _barcodes.add(barcode);
      // Sort by most recent
      _barcodes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _barcodesController.add(List.from(_barcodes));
    }
  }

  /// Handle barcode stats update
  void _handleBarcodeStats(BarcodeStats stats) {
    _barcodeStatsController.add(stats);
  }

  /// Handle barcode error
  void _handleBarcodeError(RfidError error) {
    _isBarcodeScanning = false;
    _barcodeScanningController.add(false);
    _barcodeErrorController.add(error);
  }

  /// Dispose resources
  void dispose() {
    _inventoryEventSubscription?.cancel();
    _barcodeEventSubscription?.cancel();
    _rfidTagsController.close();
    _rfidStatsController.close();
    _rfidInventoryingController.close();
    _rfidErrorController.close();
    _barcodesController.close();
    _barcodeStatsController.close();
    _barcodeScanningController.close();
    _barcodeErrorController.close();
  }
}
