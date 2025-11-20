import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/rfid_tag.dart';
import '../models/rfid_inventory_stats.dart';
import '../models/barcode_data.dart';
import '../models/barcode_stats.dart';
import '../models/rfid_error.dart';
import '../services/inventory_service.dart';
import 'scan_state_provider.dart';

part 'inventory_state_provider.g.dart';

/// Inventory mode enum
enum InventoryMode {
  rfid, // RFID tag inventory
  barcode, // Barcode scanning
}

/// RFID inventory state model
class RfidInventoryState {
  final List<RfidTag> tags;
  final RfidInventoryStats? stats;
  final bool isInventorying;
  final RfidError? error;

  const RfidInventoryState({
    this.tags = const [],
    this.stats,
    this.isInventorying = false,
    this.error,
  });

  RfidInventoryState copyWith({
    List<RfidTag>? tags,
    RfidInventoryStats? stats,
    bool? isInventorying,
    RfidError? error,
  }) {
    return RfidInventoryState(
      tags: tags ?? this.tags,
      stats: stats ?? this.stats,
      isInventorying: isInventorying ?? this.isInventorying,
      error: error ?? this.error,
    );
  }

  RfidInventoryState clearError() {
    return copyWith(error: null);
  }

  int get uniqueTagCount => tags.length;
  int get totalReads => tags.fold(0, (sum, tag) => sum + tag.count);
}

/// Barcode inventory state model
class BarcodeInventoryState {
  final List<BarcodeData> barcodes;
  final BarcodeStats? stats;
  final bool isScanning;
  final RfidError? error;

  const BarcodeInventoryState({
    this.barcodes = const [],
    this.stats,
    this.isScanning = false,
    this.error,
  });

  BarcodeInventoryState copyWith({
    List<BarcodeData>? barcodes,
    BarcodeStats? stats,
    bool? isScanning,
    RfidError? error,
  }) {
    return BarcodeInventoryState(
      barcodes: barcodes ?? this.barcodes,
      stats: stats ?? this.stats,
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
    );
  }

  BarcodeInventoryState clearError() {
    return copyWith(error: null);
  }

  int get uniqueBarcodeCount => barcodes.length;
}

/// Provide InventoryService instance
@riverpod
InventoryService inventoryService(InventoryServiceRef ref) {
  final rfidService = ref.watch(rfidServiceProvider);
  final service = InventoryService(rfidService);
  service.initialize();

  // Dispose on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// RFID inventory state provider
@riverpod
class RfidInventoryStateNotifier extends _$RfidInventoryStateNotifier {
  @override
  RfidInventoryState build() {
    final service = ref.watch(inventoryServiceProvider);

    print('📱 RfidInventoryStateNotifier: build() called, setting up stream listeners');

    // Listen to tags stream
    service.rfidTags.listen((tags) {
      print('📱 RfidInventoryStateNotifier: Tags stream emitted ${tags.length} tags');
      state = state.copyWith(tags: tags);
      print('📱 RfidInventoryStateNotifier: State updated with ${state.tags.length} tags');
    });

    // Listen to stats stream
    service.rfidStats.listen((stats) {
      state = state.copyWith(stats: stats);
    });

    // Listen to inventorying state stream
    service.isInventorying.listen((isInventorying) {
      state = state.copyWith(isInventorying: isInventorying);
    });

    // Listen to errors stream
    service.rfidErrors.listen((error) {
      state = state.copyWith(error: error);
    });

    return const RfidInventoryState();
  }

  /// Start RFID tag inventory
  Future<void> startInventory() async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.startInventory();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to start inventory',
          type: RfidErrorType.inventoryFailed,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Stop RFID tag inventory
  Future<void> stopInventory() async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.stopInventory();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to stop inventory',
          type: RfidErrorType.inventoryFailed,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Clear tags list
  void clearTags() {
    final service = ref.read(inventoryServiceProvider);
    service.clearTags();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Get tag by EPC
  RfidTag? getTagByEpc(String epc) {
    final service = ref.read(inventoryServiceProvider);
    return service.getTagByEpc(epc);
  }

  /// Sort tags by various criteria
  List<RfidTag> getSortedTags({
    required SortBy sortBy,
    required bool ascending,
  }) {
    final tags = List<RfidTag>.from(state.tags);

    switch (sortBy) {
      case SortBy.epc:
        tags.sort((a, b) =>
            ascending ? a.epc.compareTo(b.epc) : b.epc.compareTo(a.epc));
      case SortBy.rssi:
        tags.sort(
            (a, b) => ascending ? a.rssi.compareTo(b.rssi) : b.rssi.compareTo(a.rssi));
      case SortBy.count:
        tags.sort((a, b) =>
            ascending ? a.count.compareTo(b.count) : b.count.compareTo(a.count));
      case SortBy.timestamp:
        tags.sort((a, b) => ascending
            ? a.timestamp.compareTo(b.timestamp)
            : b.timestamp.compareTo(a.timestamp));
    }

    return tags;
  }
}

/// Sort criteria enum
enum SortBy {
  epc,
  rssi,
  count,
  timestamp,
}

/// Barcode inventory state provider
@riverpod
class BarcodeInventoryStateNotifier extends _$BarcodeInventoryStateNotifier {
  @override
  BarcodeInventoryState build() {
    final service = ref.watch(inventoryServiceProvider);

    // Listen to barcodes stream
    service.barcodes.listen((barcodes) {
      state = state.copyWith(barcodes: barcodes);
    });

    // Listen to stats stream
    service.barcodeStats.listen((stats) {
      state = state.copyWith(stats: stats);
    });

    // Listen to scanning state stream
    service.isBarcodeScanning.listen((isScanning) {
      state = state.copyWith(isScanning: isScanning);
    });

    // Listen to errors stream
    service.barcodeErrors.listen((error) {
      state = state.copyWith(error: error);
    });

    return const BarcodeInventoryState();
  }

  /// Start barcode scanning
  Future<void> startBarcodeScan() async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.startBarcodeScan();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to start barcode scan',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Stop barcode scanning
  Future<void> stopBarcodeScan() async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.stopBarcodeScan();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to stop barcode scan',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Clear barcodes list
  void clearBarcodes() {
    final service = ref.read(inventoryServiceProvider);
    service.clearBarcodes();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}
