import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/router/patient_preview_provider.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../data/pairing_repository.dart';
import 'glasses_qr_scanner.dart';
import 'pairing_providers.dart';

class A5PairGlassesScreen extends ConsumerStatefulWidget {
  const A5PairGlassesScreen({super.key, this.patientId});
  final String? patientId;
  @override
  ConsumerState<A5PairGlassesScreen> createState() =>
      _A5PairGlassesScreenState();
}

class _A5PairGlassesScreenState extends ConsumerState<A5PairGlassesScreen> {
  bool _scanning = false;
  int _attempt = 0;
  bool get _hasPatient =>
      widget.patientId != null && PairingRepository.isUuid(widget.patientId!);

  void _scan() {
    final state = ref.read(pairingControllerProvider);
    if (!_hasPatient || state.busy || state.info != null) return;
    if (state.failure?.kind == ApiFailureKind.credentials &&
        state.serial != null) {
      ref
          .read(pairingControllerProvider.notifier)
          .pair(widget.patientId!, state.serial!);
      return;
    }
    setState(() {
      _scanning = true;
      _attempt++;
    });
  }

  void _detected(String serial) {
    if (!_scanning || !_hasPatient || serial.trim().isEmpty) return;
    setState(() => _scanning = false);
    ref
        .read(pairingControllerProvider.notifier)
        .pair(widget.patientId!, serial);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(pairingControllerProvider);
    final linked = state.info != null;
    final failure = state.failure;
    final error = failure?.code == 'DEVICE_ALREADY_PAIRED'
        ? s.pairAlreadyPaired
        : failure?.code == 'PATIENT_NOT_FOUND'
        ? s.pairPatientMissing
        : failure?.code == 'DEVICE_NOT_FOUND' ||
              failure?.code == 'VALIDATION_ERROR'
        ? s.pairInvalidCode
        : failure?.kind == ApiFailureKind.credentials
        ? s.pairSaveFailed
        : failure?.kind == ApiFailureKind.network ||
              failure?.kind == ApiFailureKind.timeout
        ? s.loginConnectionError
        : s.pairRetry;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.goNamed(RemoriScreen.a4.name);
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: InkWell(
                        onTap: state.busy
                            ? null
                            : () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.goNamed(RemoriScreen.a4.name);
                                }
                              },
                        child: Row(
                          children: [
                            Transform.flip(
                              flipX:
                                  Directionality.of(context) ==
                                  TextDirection.rtl,
                              child: const Icon(Icons.chevron_left, size: 22),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                s.pairGlasses,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.pairStepTwo,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: RemoriColors.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: 2 / 3,
              minHeight: 3,
              color: RemoriColors.purple,
              backgroundColor: RemoriColors.purple.withValues(alpha: .18),
              semanticsLabel: s.pairStepTwo,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  if (_scanning)
                    SizedBox(
                      height: 188,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: KeyedSubtree(
                          key: ValueKey(_attempt),
                          child: ref.watch(qrScannerBuilderProvider)(
                            context,
                            _detected,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 188),
                      child: RemoriCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/pair-qr.svg',
                              width: 40,
                              height: 40,
                              excludeFromSemantics: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.pairScanTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.pairScanPosition,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    s.pairCameraHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 12),
                  ),
                  RemoriButton(
                    label: state.busy
                        ? s.pairLinking
                        : failure?.kind == ApiFailureKind.credentials
                        ? s.pairRetrySave
                        : s.pairScanButton,
                    onPressed: !_hasPatient || state.busy || linked
                        ? null
                        : _scan,
                  ),
                  Text(
                    s.pairContinueHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 12),
                  ),
                  _step(1, s.pairScanStep, s.pairScanStepDetail),
                  _step(2, s.pairConnectStep, s.pairBluetoothPending),
                  _step(3, s.pairConfirmStep, s.pairConfirmDetail),
                  RemoriCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/images/pair-info.svg',
                          width: 20,
                          height: 20,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.pairDeviceStatus,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  !_hasPatient
                                      ? s.pairNeedsPatient
                                      : linked
                                      ? s.pairLinkedPending
                                      : state.busy
                                      ? s.pairLinking
                                      : s.pairStatusInitial,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              if (linked)
                                Text(
                                  s.pairSerial(state.info!.serial),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (failure != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 4, 40, 0),
                    child: RemoriButton(
                      label: s.continueLabel,
                      onPressed: linked
                          ? () => context.pushNamed(
                              RemoriScreen.a6.name,
                              extra: widget.patientId,
                            )
                          : null,
                    ),
                  ),
                  if (patientPreviewEnabled)
                    RemoriButton(
                      label: s.patientPreviewStart,
                      outlined: true,
                      onPressed: state.busy
                          ? null
                          : () {
                              ref.read(patientPreviewProvider.notifier).start();
                              context.goNamed(RemoriScreen.p1.name);
                            },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int number, String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFD9CCF0),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: RemoriColors.purple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
