// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geiger_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geigerServiceHash() => r'faff1db6075e605dae9b3c709c48210013328987';

/// Provide GeigerService instance
///
/// Copied from [geigerService].
@ProviderFor(geigerService)
final geigerServiceProvider = AutoDisposeProvider<GeigerService>.internal(
  geigerService,
  name: r'geigerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geigerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeigerServiceRef = AutoDisposeProviderRef<GeigerService>;
String _$geigerStateNotifierHash() =>
    r'62f6388a8a38e5925fe39fe63bf2c27661f3f711';

/// Geiger state provider
///
/// Copied from [GeigerStateNotifier].
@ProviderFor(GeigerStateNotifier)
final geigerStateNotifierProvider =
    AutoDisposeNotifierProvider<GeigerStateNotifier, GeigerState>.internal(
  GeigerStateNotifier.new,
  name: r'geigerStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geigerStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GeigerStateNotifier = AutoDisposeNotifier<GeigerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
