import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../domain/patient_draft.dart';
import 'patient_setup_providers.dart';

class A4PatientProfileScreen extends ConsumerStatefulWidget {
  const A4PatientProfileScreen({super.key});
  @override
  ConsumerState<A4PatientProfileScreen> createState() =>
      _A4PatientProfileScreenState();
}

class _A4PatientProfileScreenState
    extends ConsumerState<A4PatientProfileScreen> {
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _birth = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  String _language = 'en';
  bool _conversation = false;
  bool _cloud = false;
  bool _submitted = false;

  @override
  void dispose() {
    for (final controller in [_name, _relationship, _birth, _timezone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    if (ref.read(patientSetupProvider).busy) return;
    setState(() => _submitted = true);
    final birth = _birth.text.trim();
    final date = birth.isEmpty ? null : PatientDraft.parseBirthDate(birth);
    if (_name.text.trim().isEmpty ||
        _relationship.text.trim().isEmpty ||
        (birth.isNotEmpty && date == null)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final id = await ref
        .read(patientSetupProvider.notifier)
        .create(
          PatientDraft(
            name: _name.text,
            relationship: _relationship.text,
            language: _language,
            timezone: _timezone.text,
            dateOfBirth: date,
            conversationConsent: _conversation,
            cloudConsent: _cloud,
          ),
        );
    if (mounted && id != null) {
      context.pushNamed(RemoriScreen.a5.name, extra: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(patientSetupProvider);
    final failure = state.failure;
    final error = failure?.code == 'VALIDATION_ERROR'
        ? s.signupCheckFields
        : failure?.kind == ApiFailureKind.network ||
              failure?.kind == ApiFailureKind.timeout
        ? s.loginConnectionError
        : failure?.statusCode == 401
        ? s.patientLoginAgain
        : s.patientCreateRetry;
    return SingleChildScrollView(
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
                          : () => context.goNamed(RemoriScreen.a2.name),
                      child: Row(
                        children: [
                          Transform.flip(
                            flipX:
                                Directionality.of(context) == TextDirection.rtl,
                            child: const Icon(Icons.chevron_left, size: 22),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.newPatient,
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
                  s.patientStepOne,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: RemoriColors.purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: 1 / 3,
            minHeight: 3,
            color: RemoriColors.purple,
            backgroundColor: RemoriColors.purple.withValues(alpha: .18),
            semanticsLabel: s.patientStepOne,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                _field(
                  s.patientName,
                  _name,
                  'full_name',
                  hint: s.patientNameHint,
                  required: true,
                ),
                _field(
                  s.patientRelationship,
                  _relationship,
                  'relationship',
                  required: true,
                ),
                _field(
                  s.patientBirthDate,
                  _birth,
                  'date_of_birth',
                  hint: s.patientDateHint,
                  date: true,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(s.patientLanguage),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _languageChip(s.patientEnglish, 'en'),
                        _languageChip(s.patientArabic, 'ar'),
                      ],
                    ),
                  ],
                ),
                _field(s.patientTimezone, _timezone, 'timezone', ltr: true),
                RemoriCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Text(
                        s.patientConsent,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _consent(
                        s.conversationMemory,
                        s.conversationMemoryDetail,
                        _conversation,
                        (state.busy || state.patientId != null)
                            ? null
                            : (value) => setState(() => _conversation = value),
                      ),
                      _consent(
                        s.cloudProcessing,
                        s.cloudProcessingDetail,
                        _cloud,
                        (state.busy || state.patientId != null)
                            ? null
                            : (value) => setState(() => _cloud = value),
                      ),
                      Text(
                        s.consentLater,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 12,
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
                  padding: const EdgeInsets.fromLTRB(40, 6, 40, 0),
                  child: RemoriButton(
                    label: state.busy ? s.patientCreating : s.continueLabel,
                    onPressed: state.busy ? null : _continue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String label) => Text(
    label,
    style: Theme.of(context).textTheme.labelMedium!.copyWith(
      fontFamily: Localizations.localeOf(context).languageCode == 'ar'
          ? 'Readex Pro'
          : 'Manrope',
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String field, {
    String? hint,
    bool required = false,
    bool date = false,
    bool ltr = false,
  }) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(patientSetupProvider);
    String? error;
    if (_submitted && required && controller.text.trim().isEmpty) {
      error = s.requiredField;
    }
    if (_submitted &&
        date &&
        controller.text.trim().isNotEmpty &&
        PatientDraft.parseBirthDate(controller.text) == null) {
      error = s.patientInvalidDate;
    }
    if (state.failure?.code == 'VALIDATION_ERROR' &&
        state.failure!.details.any(
          (detail) => detail.field.split('.').last == field,
        )) {
      error = s.signupInvalidField;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            enabled: !state.busy && state.patientId == null,
            textDirection: ltr || date ? TextDirection.ltr : null,
            keyboardType: date ? TextInputType.datetime : TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: !ltr && !date,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              errorText: error,
              hintTextDirection: date ? TextDirection.ltr : null,
              hintStyle: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: const Color(0x80000000)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: RemoriColors.border),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _languageChip(String label, String language) {
    final selected = _language == language;
    final setup = ref.watch(patientSetupProvider);
    final busy = setup.busy || setup.patientId != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !busy,
      child: Material(
        color: selected ? RemoriColors.purple : RemoriColors.surface,
        shape: StadiumBorder(side: BorderSide(color: RemoriColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: busy ? null : () => setState(() => _language = language),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontFamilyFallback: const ['Readex Pro'],
                fontWeight: FontWeight.w600,
                color: selected ? RemoriColors.surface : RemoriColors.purple,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _consent(
    String title,
    String detail,
    bool checked,
    ValueChanged<bool>? change,
  ) => Semantics(
    checked: checked,
    enabled: change != null,
    label: '$title. $detail',
    child: InkWell(
      onTap: change == null ? null : () => change(!checked),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: checked,
                  side: BorderSide(
                    color: RemoriColors.ink.withValues(alpha: .6),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: change == null
                      ? null
                      : (value) => change(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
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
        ),
      ),
    ),
  );
}
