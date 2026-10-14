import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/relay/glasses_connection.dart';
import '../../../core/relay/glasses_connection_provider.dart';
import '../../../core/relay/glasses_message.dart';
import '../../../core/relay/permission_service.dart';
import '../data/home_repository.dart';
import '../domain/home_data.dart';

final homeRepositoryProvider = Provider.autoDispose
    .family<HomeRepository, String>((ref, id) {
      final repo = HomeRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        id,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final homeDataProvider = StreamProvider.autoDispose<HomeData>((ref) {
  final identity = ref.watch(caregiverIdentityProvider);
  // Do not keep showing another account's previous AsyncValue while identity reloads.
  if (identity.isLoading || identity.hasError || identity.value == null) {
    return Stream.value(const HomeData());
  }
  return ref.watch(homeRepositoryProvider(identity.value!)).watch();
});
final selectedHomePatientIdProvider =
    NotifierProvider<SelectedHomePatient, String?>(SelectedHomePatient.new);

class SelectedHomePatient extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(caregiverIdentityProvider);
    return null;
  }

  void select(String id) => state = id;
}

final selectedHomePatientProvider = Provider<HomePatient?>((ref) {
  final data = ref.watch(homeDataProvider);
  if (data.isLoading || data.hasError) return null;
  final patients = data.value?.patients ?? [];
  final selected = ref.watch(selectedHomePatientIdProvider);
  return patients.where((p) => p.id == selected).firstOrNull ??
      patients.firstOrNull;
});
final caregiverCanManageProvider = Provider<bool>(
  (ref) => ref.watch(selectedHomePatientProvider)?.permission == 'manager',
);

class HomeRefreshState {
  const HomeRefreshState({this.busy = false, this.failed = false});
  final bool busy, failed;
}

final homeRefreshProvider =
    NotifierProvider.autoDispose<HomeRefresh, HomeRefreshState>(
      HomeRefresh.new,
    );

class HomeRefresh extends Notifier<HomeRefreshState> {
  @override
  HomeRefreshState build() => const HomeRefreshState();
  Future<void> refresh() async {
    if (state.busy) return;
    state = const HomeRefreshState(busy: true);
    try {
      final id = await ref.read(caregiverIdentityProvider.future);
      if (!ref.mounted) return;
      if (id != null) {
        await ref
            .read(homeRepositoryProvider(id))
            .refresh(ref.read(selectedHomePatientIdProvider));
      }
      if (ref.mounted) state = const HomeRefreshState();
    } catch (_) {
      if (ref.mounted) state = const HomeRefreshState(failed: true);
    }
  }
}

class HomeLinkState {
  const HomeLinkState({
    this.serial,
    this.connection = GlassesConnectionState.disconnected,
    this.battery,
    this.paused,
    this.live = false,
  });
  final String? serial;
  final GlassesConnectionState connection;
  final int? battery;
  final bool? paused;
  final bool live;
}

final homeLinkProvider = NotifierProvider.autoDispose<HomeLink, HomeLinkState>(
  HomeLink.new,
);

class HomeLink extends Notifier<HomeLinkState> {
  StreamSubscription<GlassesConnectionState>? _states;
  StreamSubscription<IncomingGlassesMessage>? _messages;
  int _generation = 0;
  @override
  HomeLinkState build() {
    ref.onDispose(() {
      unawaited(_states?.cancel());
      unawaited(_messages?.cancel());
    });
    return const HomeLinkState();
  }

  Future<void> prepare(HomePatient patient, HomeDevice? device) async {
    final generation = ++_generation;
    await _states?.cancel();
    await _messages?.cancel();
    if (!ref.mounted || generation != _generation) return;
    state = const HomeLinkState();
    if (device == null ||
        ref.read(permissionServiceProvider).platform !=
            PermissionPlatform.android) {
      return;
    }
    final connection = ref.read(glassesConnectionProvider);
    state = HomeLinkState(serial: device.serial);
    void streamFailed(Object _) {
      if (ref.mounted && generation == _generation) {
        state = HomeLinkState(serial: device.serial, live: true);
      }
    }

    try {
      _states = connection.states.listen((value) {
        if (ref.mounted && generation == _generation) {
          state = HomeLinkState(
            serial: device.serial,
            live: true,
            connection: value,
            battery: value == GlassesConnectionState.connected
                ? state.battery
                : null,
            paused: value == GlassesConnectionState.connected
                ? state.paused
                : null,
          );
        }
      }, onError: streamFailed);
      _messages = connection.messages.listen((message) async {
        if (!ref.mounted || generation != _generation) return;
        if (message is Hello && message.deviceSerial == device.serial) {
          try {
            await connection.send(
              TimeSync(
                utc: DateTime.now().toUtc().toIso8601String(),
                timezone: patient.timezone,
              ),
            );
          } catch (_) {
            if (ref.mounted && generation == _generation) {
              state = HomeLinkState(serial: device.serial, live: true);
            }
          }
        } else if (message is Telemetry &&
            state.connection == GlassesConnectionState.connected) {
          state = HomeLinkState(
            serial: device.serial,
            live: true,
            connection: state.connection,
            battery: message.batteryPct,
            paused: message.memoryPaused,
          );
        }
      }, onError: streamFailed);
      await connection.connect(device.serial);
    } catch (_) {
      // The approved BLE placeholder has no streams yet; API status still works.
      if (ref.mounted && generation == _generation) {
        state = HomeLinkState(serial: device.serial);
      }
    }
  }
}
