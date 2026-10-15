import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/home_data.dart';
import '../domain/more_data.dart';
import 'home_providers.dart';
import 'more_providers.dart';

class C18MoreScreen extends ConsumerStatefulWidget {
  const C18MoreScreen({super.key});
  @override
  ConsumerState<C18MoreScreen> createState() => _C18MoreScreenState();
}

class _C18MoreScreenState extends ConsumerState<C18MoreScreen>
    with WidgetsBindingObserver {
  bool _dialog = false, _visible = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final scope = ref.read(moreScopeProvider);
    if (scope != null) {
      final controller = ref.read(moreControllerProvider(scope).notifier);
      await controller.refresh();
      if (mounted && controller.loggedOut) {
        context.goNamed(RemoriScreen.a1.name);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _edit(MoreScope scope, HomePatient patient) async {
    if (_dialog || !ref.read(moreControllerProvider(scope).notifier).canWrite) {
      return;
    }
    setState(() => _dialog = true);
    final profile = await showDialog<PatientProfile>(
      context: context,
      builder: (_) => _ProfileDialog(patient: patient),
    );
    if (!mounted) return;
    setState(() => _dialog = false);
    if (profile != null && ref.read(moreScopeProvider) == scope) {
      await ref
          .read(moreControllerProvider(scope).notifier)
          .change(profile: profile);
    }
  }

  Future<void> _revoke(MoreScope scope, ConsentRecord consent) async {
    if (_dialog || !ref.read(moreControllerProvider(scope).notifier).canWrite) {
      return;
    }
    setState(() => _dialog = true);
    final s = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.moreRevokeTitle),
        content: Text(
          consent.type == 'face_enrollment'
              ? s.moreRevokeFaceHelp
              : s.moreRevokeHelp,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(s.moreRevoke),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _dialog = false);
    if (accepted == true && ref.read(moreScopeProvider) == scope) {
      await ref
          .read(moreControllerProvider(scope).notifier)
          .change(revokeId: consent.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        scope = ref.watch(moreScopeProvider),
        patient = ref.watch(selectedHomePatientProvider);
    final snapshot = scope == null ? null : ref.watch(moreDataProvider(scope));
    final data = snapshot == null || snapshot.isLoading || snapshot.hasError
        ? const MoreData()
        : snapshot.value ?? const MoreData();
    final state = scope == null
        ? const MoreState()
        : ref.watch(moreControllerProvider(scope));
    final canEdit =
        scope != null &&
        patient?.permission == 'manager' &&
        !state.busy &&
        !state.pending &&
        !state.uncertain &&
        !_dialog;
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      if (visible) {
        Future.microtask(() {
          if (mounted) _refresh();
        });
      }
    }
    final home = ref.watch(homeDataProvider);
    final devices = home.isLoading || home.hasError
        ? <HomeDevice>[]
        : home.value?.devices.where((d) => d.patientId == scope?.$2).toList() ??
              [];
    String language(String code) => code == 'ar' ? s.moreArabic : s.moreEnglish;
    Widget group(String title) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
        ),
      ),
    );
    Widget entry(
      String title,
      String subtitle, {
      VoidCallback? onTap,
      bool arrow = false,
      bool enabled = true,
      Color? color,
    }) => Semantics(
      button: onTap != null || arrow,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE6DFF2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _title.copyWith(color: color)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: _sub),
                    ],
                  ],
                ),
              ),
              if (arrow) ...[
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
    void open(RemoriScreen screen) {
      if (scope?.$2 != null) context.goNamed(screen.name);
    }

    final locale = Localizations.localeOf(context).languageCode;
    String consentName(ConsentRecord c) => switch (c.type) {
      'ambient_audio_household' => s.moreConversationConsent,
      'cloud_processing' => s.moreCloudConsent,
      _ =>
        c.subjectName?.trim().isNotEmpty == true
            ? s.moreFaceConsentFor(c.subjectName!)
            : s.moreFaceConsent,
    };
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RemoriColors.border)),
            ),
            child: Text(
              s.moreTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (scope == null) Text(s.moreUnavailable, style: _sub),
                  if (state.busy) const LinearProgressIndicator(),
                  if (state.failed || snapshot?.hasError == true) ...[
                    Text(
                      state.pending
                          ? s.morePending
                          : state.uncertain
                          ? s.moreUncertain
                          : s.moreOffline,
                      style: _sub,
                    ),
                    TextButton(
                      onPressed: state.busy ? null : _refresh,
                      child: Text(s.homeRetry),
                    ),
                  ],
                  group(s.morePatientGroup),
                  entry(
                    s.morePatientProfile,
                    patient == null
                        ? s.moreNoPatient
                        : '${patient.name} · ${language(patient.language)} · ${patient.timezone}',
                    onTap: canEdit ? () => _edit(scope, patient!) : null,
                  ),
                  entry(
                    s.moreCaregivers,
                    data.caregiverCount == null
                        ? s.caregiversMoreHelp
                        : s.caregiversLinkedCount(data.caregiverCount!),
                    arrow: true,
                    enabled: patient != null,
                    onTap: () => open(RemoriScreen.c19),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE6DFF2)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s.moreConsents, style: _title),
                        if (data.consents.isEmpty && !state.busy)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              state.failed
                                  ? s.moreConsentsUnavailable
                                  : s.moreNoConsents,
                              style: _sub,
                            ),
                          ),
                        for (final consent in data.consents)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${consentName(consent)} · ${consent.revokedAt == null ? s.moreGiven(DateFormat('d MMM', locale).format(PatientTime.local(consent.givenAt, patient?.timezone ?? 'UTC'))) : s.moreRevoked(DateFormat('d MMM', locale).format(PatientTime.local(consent.revokedAt!, patient?.timezone ?? 'UTC')))}',
                                    style: _sub.copyWith(
                                      color: RemoriColors.ink,
                                    ),
                                  ),
                                ),
                                if (consent.revokedAt == null &&
                                    patient?.permission == 'manager') ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: canEdit
                                        ? () => _revoke(scope, consent)
                                        : null,
                                    child: Text(
                                      s.moreRevoke,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: canEdit
                                            ? RemoriColors.purple
                                            : RemoriColors.muted,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  entry(
                    s.moreJournal,
                    s.moreJournalHelp,
                    arrow: true,
                    enabled: patient != null,
                    onTap: () => open(RemoriScreen.c12),
                  ),
                  entry(
                    s.morePlaces,
                    data.placeCount == null
                        ? s.morePlacesHelp
                        : s.morePlacesCount(data.placeCount!),
                    arrow: true,
                    enabled: patient != null,
                    onTap: () => open(RemoriScreen.c10),
                  ),
                  entry(
                    s.moreDocuments,
                    s.moreDocumentsHelp,
                    arrow: true,
                    enabled: patient != null,
                    onTap: () => open(RemoriScreen.c14),
                  ),
                  entry(
                    s.deviceTitle,
                    devices.length == 1
                        ? s.moreDeviceSerial(devices.single.serial)
                        : s.moreDeviceHelp,
                    arrow: true,
                    enabled: patient != null,
                    onTap: () => open(RemoriScreen.c16),
                  ),
                  group(s.moreAccountGroup),
                  entry(
                    s.moreMyAccount,
                    data.account == null
                        ? s.moreAccountUnavailable
                        : '${data.account!.name} · ${data.account!.email}',
                  ),
                  entry(
                    s.moreConnectedAccounts,
                    s.moreConnectedPending,
                    arrow: true,
                    enabled: false,
                  ),
                  entry(
                    s.moreLogout,
                    '',
                    color: const Color(0xFFA6412A),
                    enabled: scope != null && !state.busy && !state.pending,
                    onTap: scope == null
                        ? null
                        : () async {
                            final success = await ref
                                .read(moreControllerProvider(scope).notifier)
                                .logout();
                            if (context.mounted && success) {
                              context.goNamed(RemoriScreen.a1.name);
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.patient});
  final HomePatient patient;
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.patient.name),
      _timezone = TextEditingController(text: widget.patient.timezone);
  late String _language = widget.patient.language;
  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.morePatientProfile),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: s.moreFullName,
                  hintText: s.moreNameHint,
                ),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : s.moreProfileInvalid,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _language,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.moreLanguage),
                items: [
                  DropdownMenuItem(value: 'ar', child: Text(s.moreArabic)),
                  DropdownMenuItem(value: 'en', child: Text(s.moreEnglish)),
                ],
                onChanged: (value) => setState(() => _language = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timezone,
                decoration: InputDecoration(
                  labelText: s.moreTimezone,
                  hintText: s.moreTimezoneHint,
                ),
                validator: (value) =>
                    PatientProfile(
                      _name.text,
                      _language,
                      value?.trim() ?? '',
                    ).isValid
                    ? null
                    : s.moreProfileInvalid,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              context.pop(
                PatientProfile(
                  _name.text.trim(),
                  _language,
                  _timezone.text.trim(),
                ),
              );
            }
          },
          child: Text(s.moreSave),
        ),
      ],
    );
  }
}

const _title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
const _sub = TextStyle(
  fontSize: 13,
  height: 1.3,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);
