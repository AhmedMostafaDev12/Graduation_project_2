import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/reminder_data.dart';
import 'reminders_providers.dart';

class ReminderEditorKey {
  const ReminderEditorKey(this.scope, this.id);
  final ReminderScope scope;
  final String? id;
  @override
  bool operator ==(Object other) =>
      other is ReminderEditorKey && other.scope == scope && other.id == id;
  @override
  int get hashCode => Object.hash(scope, id);
}

class ReminderEditorState {
  const ReminderEditorState({
    this.busy = false,
    this.acknowledged = false,
    this.deleting = false,
    this.failure,
  });
  final bool busy, acknowledged, deleting;
  final ApiFailure? failure;
}

final reminderEditorProvider = NotifierProvider.autoDispose
    .family<ReminderEditorController, ReminderEditorState, ReminderEditorKey>(
      ReminderEditorController.new,
    );

class ReminderEditorController extends Notifier<ReminderEditorState> {
  ReminderEditorController(this.owner);
  final ReminderEditorKey owner;
  CachedRemindersCompanion? _saved;
  bool _deleted = false;
  @override
  ReminderEditorState build() {
    try {
      ref.watch(remindersRepositoryProvider(owner.scope));
    } catch (_) {
      /* Report safely on save. */
    }
    return ReminderEditorState(
      acknowledged: _saved != null || _deleted,
      deleting: _deleted,
    );
  }

  bool get _allowed =>
      ref.mounted &&
      ref.read(reminderScopeProvider) == owner.scope &&
      ref.read(caregiverCanManageProvider);

  Future<bool> save(Map<String, Object?> payload) => _write(payload, false);
  Future<bool> delete() => _write(const {}, true);
  Future<bool> _write(Map<String, Object?> payload, bool deleting) async {
    if (!_allowed ||
        state.busy ||
        (deleting && owner.id == null) ||
        (_saved != null && deleting) ||
        (_deleted && !deleting)) {
      return false;
    }
    state = ReminderEditorState(
      busy: true,
      acknowledged: _saved != null || _deleted,
      deleting: deleting,
    );
    try {
      final repo = ref.read(remindersRepositoryProvider(owner.scope));
      if (deleting) {
        if (!_deleted) {
          await repo.delete(owner.id!);
          _deleted = true;
        }
      } else {
        _saved ??= await repo.save(payload, id: owner.id);
      }
      if (!_allowed) return false;
      state = ReminderEditorState(
        busy: true,
        acknowledged: true,
        deleting: deleting,
      );
      if (deleting) {
        await repo.cacheDelete(owner.id!);
      } else {
        await repo.cacheToggle(_saved!);
      }
      if (!_allowed) return false;
      state = ReminderEditorState(acknowledged: true, deleting: deleting);
      return true;
    } catch (error) {
      if (_allowed) {
        state = ReminderEditorState(
          acknowledged: _saved != null || _deleted,
          deleting: deleting,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
      return false;
    } finally {
      if (_allowed && state.busy) {
        state = ReminderEditorState(
          acknowledged: _saved != null || _deleted,
          deleting: deleting,
        );
      }
    }
  }
}
