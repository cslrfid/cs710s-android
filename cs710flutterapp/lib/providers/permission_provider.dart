import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/permission_service.dart';

part 'permission_provider.g.dart';

/// Provider for permission service
@riverpod
PermissionService permissionService(PermissionServiceRef ref) {
  return PermissionService();
}

/// Provider for checking permission status
@riverpod
Future<bool> hasPermissions(HasPermissionsRef ref) async {
  final service = ref.watch(permissionServiceProvider);
  return await service.checkPermissions();
}
