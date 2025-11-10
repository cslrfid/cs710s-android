import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/rfid_reader.dart';
import '../models/rfid_error.dart';
import '../services/rfid_service.dart';
import '../services/scan_service.dart';
import '../platform_channels/rfid_channel.dart';

part 'scan_state_provider.g.dart';

/// Scan state model
class ScanState {
  final List<RfidReader> readers;
  final bool isScanning;
  final RfidError? error;

  const ScanState({
    this.readers = const [],
    this.isScanning = false,
    this.error,
  });

  ScanState copyWith({
    List<RfidReader>? readers,
    bool? isScanning,
    RfidError? error,
  }) {
    return ScanState(
      readers: readers ?? this.readers,
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
    );
  }

  /// Clear error
  ScanState clearError() {
    return copyWith(error: null);
  }
}

/// Provide RfidChannel instance
@riverpod
RfidChannel rfidChannel(RfidChannelRef ref) {
  return RfidChannel();
}

/// Provide RfidService instance
@riverpod
RfidService rfidService(RfidServiceRef ref) {
  final channel = ref.watch(rfidChannelProvider);
  return RfidService(channel);
}

/// Provide ScanService instance
@riverpod
ScanService scanService(ScanServiceRef ref) {
  final rfidService = ref.watch(rfidServiceProvider);
  final service = ScanService(rfidService);
  service.initialize();

  // Dispose on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Scan state provider
@riverpod
class ScanStateNotifier extends _$ScanStateNotifier {
  @override
  ScanState build() {
    final service = ref.watch(scanServiceProvider);

    // Listen to readers stream
    service.readers.listen((readers) {
      state = state.copyWith(readers: readers);
    });

    // Listen to scanning state stream
    service.isScanning.listen((isScanning) {
      state = state.copyWith(isScanning: isScanning);
    });

    // Listen to errors stream
    service.errors.listen((error) {
      state = state.copyWith(error: error);
    });

    return const ScanState();
  }

  /// Start scanning for RFID readers
  Future<void> startScan() async {
    final service = ref.read(scanServiceProvider);
    try {
      await service.startScan();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to start scan',
          type: RfidErrorType.scanFailed,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Stop scanning for RFID readers
  Future<void> stopScan() async {
    final service = ref.read(scanServiceProvider);
    try {
      await service.stopScan();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to stop scan',
          type: RfidErrorType.scanFailed,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Clear discovered readers list
  void clearReaders() {
    final service = ref.read(scanServiceProvider);
    service.clearReaders();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Get reader by address
  RfidReader? getReaderByAddress(String address) {
    return state.readers.firstWhere(
      (r) => r.address == address,
      orElse: () => throw StateError('Reader not found'),
    );
  }
}
