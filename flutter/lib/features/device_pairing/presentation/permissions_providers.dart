import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/relay/permission_service.dart';

class SetupPermissionsState {
  const SetupPermissionsState({
    this.busy = true,
    this.values = const {},
    this.failed = false,
  });
  final bool busy;
  final Map<SetupPermission, PermissionAccess> values;
  final bool failed;
}

final setupPermissionsProvider =
    NotifierProvider.autoDispose<
      SetupPermissionsController,
      SetupPermissionsState
    >(SetupPermissionsController.new);

class SetupPermissionsController extends Notifier<SetupPermissionsState> {
  bool _working = false;
  @override
  SetupPermissionsState build() {
    Future.microtask(refresh);
    return const SetupPermissionsState();
  }

  Future<void> refresh() async {
    if (_working) return;
    _working = true;
    try {
      final values = await ref.read(permissionServiceProvider).read();
      if (ref.mounted) {
        state = SetupPermissionsState(
          busy: false,
          values: Map.unmodifiable(values),
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = SetupPermissionsState(busy: false, failed: true);
      }
    } finally {
      _working = false;
    }
  }

  Future<void> request(SetupPermission kind) async {
    if (_working) return;
    _working = true;
    state = SetupPermissionsState(values: state.values);
    try {
      final service = ref.read(permissionServiceProvider);
      await service.request(kind);
      final values = await service.read();
      if (ref.mounted) {
        state = SetupPermissionsState(
          busy: false,
          values: Map.unmodifiable(values),
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = SetupPermissionsState(busy: false, failed: true);
      }
    } finally {
      _working = false;
    }
  }
}
