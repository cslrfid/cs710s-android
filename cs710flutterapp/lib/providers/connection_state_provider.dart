import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/rfid_reader.dart';
import '../models/rfid_error.dart';
import '../services/rfid_service.dart';
import 'scan_state_provider.dart';

part 'connection_state_provider.g.dart';

/// Connection status enum
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  ready, // Connected and reader is ready for operations
}

/// Connection state model
class ConnectionState {
  final ConnectionStatus status;
  final RfidReader? connectedReader;
  final RfidError? error;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.connectedReader,
    this.error,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    RfidReader? connectedReader,
    RfidError? error,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      connectedReader: connectedReader ?? this.connectedReader,
      error: error ?? this.error,
    );
  }

  /// Clear error
  ConnectionState clearError() {
    return ConnectionState(
      status: status,
      connectedReader: connectedReader,
      error: null,
    );
  }

  /// Check if connected (includes ready state)
  bool get isConnected =>
      status == ConnectionStatus.connected || status == ConnectionStatus.ready;

  /// Check if ready for operations
  bool get isReady => status == ConnectionStatus.ready;
}

/// Connection state provider
@riverpod
class ConnectionStateNotifier extends _$ConnectionStateNotifier {
  StreamSubscription<ConnectionEvent>? _connectionEventSubscription;

  @override
  ConnectionState build() {
    final rfidService = ref.watch(rfidServiceProvider);

    // Listen to connection events
    _connectionEventSubscription = rfidService.connectionEvents.listen(
      _handleConnectionEvent,
      onError: (error) {
        state = state.copyWith(
          error: RfidError(
            message: 'Connection event error: $error',
            type: RfidErrorType.unknown,
          ),
        );
      },
    );

    // Cleanup subscription on dispose
    ref.onDispose(() {
      _connectionEventSubscription?.cancel();
    });

    return const ConnectionState();
  }

  /// Handle connection events from service
  void _handleConnectionEvent(ConnectionEvent event) {
    switch (event) {
      case ConnectingEvent():
        state = state.copyWith(
          status: ConnectionStatus.connecting,
          error: null,
        );

      case ConnectedEvent():
        state = state.copyWith(
          status: ConnectionStatus.connected,
          connectedReader: event.reader,
          error: null,
        );

      case ReaderReadyEvent():
        state = state.copyWith(
          status: ConnectionStatus.ready,
          connectedReader: event.reader,
          error: null,
        );

      case DisconnectedEvent():
        state = ConnectionState(
          status: ConnectionStatus.disconnected,
          connectedReader: null,
          error: null,
        );

      case ConnectionFailedEvent():
        state = state.copyWith(
          status: ConnectionStatus.disconnected,
          connectedReader: null,
          error: event.error,
        );
    }
  }

  /// Connect to RFID reader by address
  Future<void> connect(String address) async {
    final rfidService = ref.read(rfidServiceProvider);

    try {
      // Update state to connecting
      state = state.copyWith(
        status: ConnectionStatus.connecting,
        error: null,
      );

      await rfidService.connect(address);
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        error: RfidError(
          message: 'Failed to connect',
          type: RfidErrorType.connectionFailed,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Disconnect from current reader
  Future<void> disconnect() async {
    final rfidService = ref.read(rfidServiceProvider);

    try {
      await rfidService.disconnect();
      state = const ConnectionState(
        status: ConnectionStatus.disconnected,
        connectedReader: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to disconnect',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Check connection status (one-time query)
  Future<bool> checkIsConnected() async {
    final rfidService = ref.read(rfidServiceProvider);
    try {
      return await rfidService.isConnected();
    } catch (e) {
      return false;
    }
  }

  /// Get connected reader info (one-time query)
  Future<void> refreshConnectedReader() async {
    final rfidService = ref.read(rfidServiceProvider);
    try {
      final reader = await rfidService.getConnectedReader();
      if (reader != null) {
        state = state.copyWith(
          status: ConnectionStatus.ready,
          connectedReader: reader,
        );
      }
    } catch (e) {
      // Ignore errors during refresh
    }
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}
