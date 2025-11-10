import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/rfid_geiger_stats.dart';
import '../models/rfid_error.dart';
import '../services/geiger_service.dart';
import 'scan_state_provider.dart';

part 'geiger_state_provider.g.dart';

/// Geiger search state model
class GeigerState {
  final RfidGeigerStats? stats;
  final bool isSearching;
  final String? targetEpc;
  final RfidError? error;

  const GeigerState({
    this.stats,
    this.isSearching = false,
    this.targetEpc,
    this.error,
  });

  GeigerState copyWith({
    RfidGeigerStats? stats,
    bool? isSearching,
    String? targetEpc,
    RfidError? error,
  }) {
    return GeigerState(
      stats: stats ?? this.stats,
      isSearching: isSearching ?? this.isSearching,
      targetEpc: targetEpc ?? this.targetEpc,
      error: error ?? this.error,
    );
  }

  GeigerState clearError() {
    return copyWith(error: null);
  }

  /// Get proximity percentage (0-100)
  double get proximity => (stats?.proximity ?? 0.0).toDouble();

  /// Get proximity bars (0-5)
  int get proximityBars {
    if (proximity <= 20) return 1;
    if (proximity <= 40) return 2;
    if (proximity <= 60) return 3;
    if (proximity <= 80) return 4;
    return 5;
  }

  /// Get proximity description
  String get proximityDescription {
    if (!isSearching) return 'Not Searching';
    if (proximity < 20) return 'Very Far';
    if (proximity < 40) return 'Far';
    if (proximity < 60) return 'Medium';
    if (proximity < 80) return 'Close';
    return 'Very Close';
  }

  /// Check if tag has been found (proximity > 0)
  bool get isTagFound => proximity > 0;
}

/// Provide GeigerService instance
@riverpod
GeigerService geigerService(GeigerServiceRef ref) {
  final rfidService = ref.watch(rfidServiceProvider);
  final service = GeigerService(rfidService);
  service.initialize();

  // Dispose on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Geiger state provider
@riverpod
class GeigerStateNotifier extends _$GeigerStateNotifier {
  @override
  GeigerState build() {
    final service = ref.watch(geigerServiceProvider);

    // Listen to stats stream
    service.stats.listen((stats) {
      state = state.copyWith(stats: stats);
    });

    // Listen to searching state stream
    service.isSearching.listen((isSearching) {
      state = state.copyWith(isSearching: isSearching);
    });

    // Listen to target EPC stream
    service.targetEpc.listen((targetEpc) {
      state = state.copyWith(targetEpc: targetEpc);
    });

    // Listen to errors stream
    service.errors.listen((error) {
      state = state.copyWith(error: error);
    });

    return const GeigerState();
  }

  /// Start Geiger search for specific tag
  /// [epc] Target EPC to search for
  /// [memoryBank] Memory bank to use (1=EPC, 2=TID, 3=User)
  Future<void> startGeigerSearch(String epc, {int memoryBank = 1}) async {
    final service = ref.read(geigerServiceProvider);

    if (epc.isEmpty) {
      state = state.copyWith(
        error: const RfidError(
          message: 'EPC cannot be empty',
          type: RfidErrorType.unknown,
        ),
      );
      return;
    }

    try {
      await service.startGeigerSearch(epc, memoryBank: memoryBank);
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to start Geiger search',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Stop Geiger search
  Future<void> stopGeigerSearch() async {
    final service = ref.read(geigerServiceProvider);
    try {
      await service.stopGeigerSearch();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to stop Geiger search',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Clear current search data
  void clearSearch() {
    final service = ref.read(geigerServiceProvider);
    service.clearSearch();
    state = const GeigerState();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Get proximity percentage for UI display
  double getProximityPercentage() {
    return state.proximity;
  }

  /// Get proximity bars (0-5) for visual indicator
  int getProximityBars() {
    return state.proximityBars;
  }

  /// Get proximity level description
  String getProximityDescription() {
    return state.proximityDescription;
  }

  /// Check if target tag has been found recently
  bool isTagFound() {
    return state.isTagFound;
  }

  /// Get elapsed time in seconds
  int getElapsedSeconds() {
    return state.stats?.elapsedSeconds ?? 0;
  }

  /// Get current RSSI value
  double? getCurrentRssi() {
    return state.stats?.currentRssi;
  }

  /// Get peak RSSI value
  double? getPeakRssi() {
    return state.stats?.peakRssi;
  }

  /// Get read count
  int getReadCount() {
    return state.stats?.readCount ?? 0;
  }
}
