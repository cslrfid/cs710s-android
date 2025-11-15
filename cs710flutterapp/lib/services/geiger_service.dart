import 'dart:async';
import '../models/rfid_geiger_stats.dart';
import '../models/rfid_error.dart';
import 'rfid_service.dart';

/// Service for managing Geiger search (tag locating) operations
class GeigerService {
  final RfidService _rfidService;

  final _statsController = StreamController<RfidGeigerStats>.broadcast();
  final _searchingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<RfidError>.broadcast();
  final _targetEpcController = StreamController<String?>.broadcast();

  StreamSubscription<GeigerEvent>? _geigerEventSubscription;

  bool _isSearching = false;
  String? _currentTargetEpc;
  RfidGeigerStats? _currentStats;

  GeigerService(this._rfidService);

  /// Stream of Geiger statistics (proximity updates)
  Stream<RfidGeigerStats> get stats => _statsController.stream;

  /// Stream of searching state
  Stream<bool> get isSearching => _searchingController.stream;

  /// Stream of Geiger errors
  Stream<RfidError> get errors => _errorController.stream;

  /// Stream of target EPC changes
  Stream<String?> get targetEpc => _targetEpcController.stream;

  /// Get current searching state
  bool get searching => _isSearching;

  /// Get current target EPC
  String? get currentTargetEpc => _currentTargetEpc;

  /// Get current Geiger statistics
  RfidGeigerStats? get currentStats => _currentStats;

  /// Initialize service - start listening to Geiger events
  void initialize() {
    _geigerEventSubscription = _rfidService.geigerEvents.listen(
      _handleGeigerEvent,
      onError: (error) {
        _errorController.add(RfidError(
          message: 'Geiger event stream error: $error',
          type: RfidErrorType.unknown,
        ));
      },
    );
  }

  /// Start Geiger search for specific tag
  /// [epc] Target EPC to search for
  /// [memoryBank] Memory bank to use (1=EPC, 2=TID, 3=User)
  Future<void> startGeigerSearch(String epc, {int memoryBank = 1}) async {
    if (epc.isEmpty) {
      throw ArgumentError('EPC cannot be empty');
    }

    try {
      await _rfidService.startGeigerSearch(epc, memoryBank: memoryBank);
      _isSearching = true;
      _currentTargetEpc = epc;
      _currentStats = null;

      _searchingController.add(true);
      _targetEpcController.add(epc);
    } catch (e) {
      _isSearching = false;
      _searchingController.add(false);
      _errorController.add(RfidError(
        message: 'Failed to start Geiger search',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Stop Geiger search
  Future<void> stopGeigerSearch() async {
    try {
      await _rfidService.stopGeigerSearch();
      _isSearching = false;
      _searchingController.add(false);
    } catch (e) {
      _errorController.add(RfidError(
        message: 'Failed to stop Geiger search',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Clear current search data
  void clearSearch() {
    _currentTargetEpc = null;
    _currentStats = null;
    _targetEpcController.add(null);
  }

  /// Handle Geiger events from RfidService
  void _handleGeigerEvent(GeigerEvent event) {
    switch (event) {
      case ProximityUpdateEvent():
        _handleProximityUpdate(event.stats);
      case GeigerStartedEvent():
        _handleGeigerStarted(event.targetEpc);
      case GeigerStoppedEvent():
        _handleGeigerStopped(event.stats);
      case GeigerErrorEvent():
        _handleGeigerError(event.error);
    }
  }

  /// Handle proximity update event
  void _handleProximityUpdate(RfidGeigerStats stats) {
    _currentStats = stats;
    _statsController.add(stats);
  }

  /// Handle Geiger started event
  void _handleGeigerStarted(String targetEpc) {
    _isSearching = true;
    _currentTargetEpc = targetEpc;
    _searchingController.add(true);
    _targetEpcController.add(targetEpc);
  }

  /// Handle Geiger stopped event
  void _handleGeigerStopped(RfidGeigerStats stats) {
    _isSearching = false;
    _currentStats = stats;
    _searchingController.add(false);
    _statsController.add(stats);
  }

  /// Handle Geiger error event
  void _handleGeigerError(RfidError error) {
    _isSearching = false;
    _searchingController.add(false);
    _errorController.add(error);
  }

  /// Get proximity percentage (0-100) from stats
  double? getProximityPercentage() {
    return _currentStats?.proximity.toDouble();
  }

  /// Get visual proximity indicator (0-5 bars)
  /// 0-20% = 1 bar, 21-40% = 2 bars, etc.
  int getProximityBars() {
    final proximity = _currentStats?.proximity;
    if (proximity == null) return 0;

    if (proximity <= 20) return 1;
    if (proximity <= 40) return 2;
    if (proximity <= 60) return 3;
    if (proximity <= 80) return 4;
    return 5;
  }

  /// Get proximity level description
  String getProximityDescription() {
    final proximity = _currentStats?.proximity;
    if (proximity == null) return 'Searching...';

    if (proximity < 20) return 'Very Far';
    if (proximity < 40) return 'Far';
    if (proximity < 60) return 'Medium';
    if (proximity < 80) return 'Close';
    return 'Very Close';
  }

  /// Check if target tag has been found recently
  /// (proximity > 0 means tag is being read)
  bool get isTagFound => (_currentStats?.proximity ?? 0) > 0;

  /// Get elapsed time in seconds
  int get elapsedSeconds => _currentStats?.elapsedSeconds ?? 0;

  /// Dispose resources
  void dispose() {
    _geigerEventSubscription?.cancel();
    _statsController.close();
    _searchingController.close();
    _errorController.close();
    _targetEpcController.close();
  }
}
