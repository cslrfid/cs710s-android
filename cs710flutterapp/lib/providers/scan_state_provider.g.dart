// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rfidChannelHash() => r'59df7fbd85b7c9e4068a11632ad1469d81aabb34';

/// Provide RfidChannel instance
///
/// Copied from [rfidChannel].
@ProviderFor(rfidChannel)
final rfidChannelProvider = AutoDisposeProvider<RfidChannel>.internal(
  rfidChannel,
  name: r'rfidChannelProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rfidChannelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RfidChannelRef = AutoDisposeProviderRef<RfidChannel>;
String _$rfidServiceHash() => r'15f2e2fb67607d19a6300959a5b9254d74077931';

/// Provide RfidService instance
///
/// Copied from [rfidService].
@ProviderFor(rfidService)
final rfidServiceProvider = AutoDisposeProvider<RfidService>.internal(
  rfidService,
  name: r'rfidServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rfidServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RfidServiceRef = AutoDisposeProviderRef<RfidService>;
String _$scanServiceHash() => r'a1832ab97c3d4056500de595b0fae365a80b3623';

/// Provide ScanService instance
///
/// Copied from [scanService].
@ProviderFor(scanService)
final scanServiceProvider = AutoDisposeProvider<ScanService>.internal(
  scanService,
  name: r'scanServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanServiceRef = AutoDisposeProviderRef<ScanService>;
String _$scanStateNotifierHash() => r'd529a231c56fb22bae06e9b516d7d02c9fe8c8d7';

/// Scan state provider
///
/// Copied from [ScanStateNotifier].
@ProviderFor(ScanStateNotifier)
final scanStateNotifierProvider =
    AutoDisposeNotifierProvider<ScanStateNotifier, ScanState>.internal(
  ScanStateNotifier.new,
  name: r'scanStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scanStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScanStateNotifier = AutoDisposeNotifier<ScanState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
