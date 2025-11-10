// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battery_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$batteryServiceHash() => r'82156005e89fe519cfbdc7be7ece7eefad8d0c00';

/// Provide BatteryService instance
///
/// Copied from [batteryService].
@ProviderFor(batteryService)
final batteryServiceProvider = AutoDisposeProvider<BatteryService>.internal(
  batteryService,
  name: r'batteryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batteryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BatteryServiceRef = AutoDisposeProviderRef<BatteryService>;
String _$batteryStateNotifierHash() =>
    r'20a76ee2389d235322d7e17c4aea9c0e6678b6fe';

/// Battery state provider
///
/// Copied from [BatteryStateNotifier].
@ProviderFor(BatteryStateNotifier)
final batteryStateNotifierProvider =
    AutoDisposeNotifierProvider<BatteryStateNotifier, BatteryState>.internal(
  BatteryStateNotifier.new,
  name: r'batteryStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batteryStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BatteryStateNotifier = AutoDisposeNotifier<BatteryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
