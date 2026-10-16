import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../features/patient_today/domain/patient_today_data.dart';
import '../../features/patient_today/presentation/patient_today_providers.dart';
import '../../features/reminders/domain/reminder_data.dart';
import '../router/remori_router.dart';
import '../router/remori_routes.dart';
import 'permission_service.dart';

/// Receipts are random and memory-only; an Intent never grants patient access.
class ReminderReceipt {
  PatientReminderAlertTarget? target;
  String? token;
  String? select(PatientReminderAlertTarget? value) {
    if (target != value) {
      target = value;
      token = value == null ? null : const Uuid().v4();
    }
    return token;
  }

  PatientReminderAlertTarget? resolve(Object? value) =>
      value != null && value == token ? target : null;
}

class ReminderNotificationHost extends ConsumerStatefulWidget {
  const ReminderNotificationHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ReminderNotificationHost> createState() =>
      _ReminderNotificationHostState();
}

class _ReminderNotificationHostState
    extends ConsumerState<ReminderNotificationHost>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('remori/reminders');
  late final Future<void> _dates;
  final _receipt = ReminderReceipt();
  Timer? _timer;
  Map<Object?, Object?>? _pending;
  bool _cleared = false;
  bool _taking = false, _takeAgain = false, _acting = false;
  late final bool _android;
  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _dates = initializeDateFormatting();
    _android =
        ref.read(permissionPlatformProvider) == PermissionPlatform.android;
    WidgetsBinding.instance.addObserver(this);
    if (_android) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'open') await _take();
      });
      // Also retries delivery after the asynchronous native D1 startup.
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
      Future.microtask(_take);
    }
  }

  Future<void> _take() async {
    if (!mounted) return;
    if (_taking) {
      _takeAgain = true;
      return;
    }
    _taking = true;
    try {
      final value = await _channel.invokeMapMethod<Object?, Object?>('take');
      if (mounted && value != null) _pending = value;
    } catch (_) {
      // Unsupported or detached engine.
    } finally {
      _taking = false;
    }
    if (mounted) unawaited(_act());
    if (mounted && _takeAgain) {
      _takeAgain = false;
      unawaited(_take());
    }
  }

  Future<void> _act() async {
    if (!mounted || !_foreground || _acting || _pending == null) return;
    final value = _pending!;
    final target = _receipt.resolve(value['token']);
    if (target == null || ref.read(patientTodayKeyProvider) != target.scope) {
      _pending = null;
      return;
    }
    // Keep the controller alive during local save and its asynchronous upload.
    if (ref.read(patientTodayControllerProvider(target.scope)).busy) return;
    _acting = true;
    _pending = null;
    try {
      final data = await ref
          .read(patientTodayRepositoryProvider(target.scope))
          .read();
      if (!mounted || ref.read(patientTodayKeyProvider) != target.scope) return;
      if (data.next?.id != target.id ||
          data.next?.dueAt != target.dueAt ||
          target.dueAt.isAfter(ref.read(patientTodayClockProvider)())) {
        return;
      }
      final action = value['action'];
      if (!{'open', 'taken', 'later'}.contains(action)) return;
      var saved = false;
      if (action != 'open') {
        saved = await ref
            .read(patientTodayControllerProvider(target.scope).notifier)
            .confirmAlert(target, snooze: action == 'later');
      }
      if (!mounted ||
          !_foreground ||
          ref.read(patientTodayKeyProvider) != target.scope) {
        return;
      }
      ref
          .read(remoriRouterProvider)
          .goNamed(
            saved ? RemoriScreen.p2.name : RemoriScreen.p3.name,
            extra: saved ? null : target,
          );
    } catch (_) {
      // No server action is repeated and no success is shown without a local save.
    } finally {
      _acting = false;
    }
  }

  Future<void> _sync() async {
    if (!mounted || !_android) return;
    await _dates;
    if (!mounted) return;
    final key = ref.read(patientTodayKeyProvider);
    final data = key == null
        ? null
        : ref.read(patientTodayDataProvider(key)).value;
    final next = data?.next;
    final target = key == null || next == null || data?.settings == null
        ? null
        : (scope: key, id: next.id, dueAt: next.dueAt);
    final token = _receipt.select(target);
    try {
      Map<String, Object>? payload;
      if (token != null && next != null) {
        final settings = data!.settings!;
        final local = tz.TZDateTime.from(
          next.dueAt,
          PatientTime.location(settings.timezone),
        );
        payload = {
          'token': token,
          'due': next.dueAt.millisecondsSinceEpoch,
          'title': next.title,
          'time': DateFormat.jm(settings.language).format(local),
          'language': settings.language,
        };
      }
      if (payload != null || !_cleared) {
        await _channel.invokeMethod<bool>('update', payload);
        _cleared = payload == null;
      }
    } catch (_) {
      // Notification denial never prevents local reminder actions.
    }
    if (mounted) unawaited(_act());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _android) unawaited(_take());
  }

  @override
  Widget build(BuildContext context) {
    final key = ref.watch(patientTodayKeyProvider);
    ref.listen(patientTodayKeyProvider, (_, _) => Future.microtask(_sync));
    if (_android && key != null) {
      ref.watch(patientTodayDataProvider(key));
      ref.watch(patientTodayControllerProvider(key));
      ref.listen(
        patientTodayDataProvider(key),
        (_, _) => Future.microtask(_sync),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_android) {
      _channel.setMethodCallHandler(null);
      unawaited(
        _channel.invokeMethod<void>('update').catchError((Object _) {}),
      );
    }
    super.dispose();
  }
}
