// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inventoryServiceHash() => r'c683f305fba32946d4c341718165ff9ddb333ca3';

/// Provide InventoryService instance
///
/// Copied from [inventoryService].
@ProviderFor(inventoryService)
final inventoryServiceProvider = AutoDisposeProvider<InventoryService>.internal(
  inventoryService,
  name: r'inventoryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InventoryServiceRef = AutoDisposeProviderRef<InventoryService>;
String _$rfidInventoryStateNotifierHash() =>
    r'6206b155162d23a2b74cbd7aa44c516919747806';

/// RFID inventory state provider
///
/// Copied from [RfidInventoryStateNotifier].
@ProviderFor(RfidInventoryStateNotifier)
final rfidInventoryStateNotifierProvider = AutoDisposeNotifierProvider<
    RfidInventoryStateNotifier, RfidInventoryState>.internal(
  RfidInventoryStateNotifier.new,
  name: r'rfidInventoryStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rfidInventoryStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RfidInventoryStateNotifier = AutoDisposeNotifier<RfidInventoryState>;
String _$barcodeInventoryStateNotifierHash() =>
    r'2d5c4c183afa1036d9f6a3c71ed29a57bc014f06';

/// Barcode inventory state provider
///
/// Copied from [BarcodeInventoryStateNotifier].
@ProviderFor(BarcodeInventoryStateNotifier)
final barcodeInventoryStateNotifierProvider = AutoDisposeNotifierProvider<
    BarcodeInventoryStateNotifier, BarcodeInventoryState>.internal(
  BarcodeInventoryStateNotifier.new,
  name: r'barcodeInventoryStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$barcodeInventoryStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BarcodeInventoryStateNotifier
    = AutoDisposeNotifier<BarcodeInventoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
