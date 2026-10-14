import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/enrollment_photo_picker.dart';
import '../domain/people_data.dart';
import '../domain/person_enrollment.dart';
import 'people_providers.dart';
import 'person_enrollment_providers.dart';

class C4AddPersonScreen extends ConsumerWidget {
  const C4AddPersonScreen({super.key, this.patientId});
  final String? patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(peopleScopeProvider);
    if (scope == null ||
        (patientId != null && patientId != scope.patientId) ||
        !ref.watch(caregiverCanManageProvider)) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, false),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).personUnavailable),
            ),
          ],
        ),
      );
    }
    return _EnrollmentForm(key: ValueKey(scope), scope: scope);
  }
}

Widget _header(BuildContext context, bool busy) => Container(
  padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
  decoration: const BoxDecoration(
    border: Border(bottom: BorderSide(color: RemoriColors.border)),
  ),
  child: Row(
    children: [
      SizedBox(
        width: 32,
        height: 38,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: busy ? null : () => context.goNamed(RemoriScreen.c3.name),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left, size: 26),
        ),
      ),
      Expanded(
        child: Text(
          AppLocalizations.of(context).personAddTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  ),
);

class _EnrollmentForm extends ConsumerStatefulWidget {
  const _EnrollmentForm({super.key, required this.scope});
  final PeopleScope scope;
  @override
  ConsumerState<_EnrollmentForm> createState() => _EnrollmentFormState();
}

class _EnrollmentFormState extends ConsumerState<_EnrollmentForm> {
  final _name = TextEditingController(),
      _relationship = TextEditingController();
  final _photos = <EnrollmentPhoto>[];
  bool _consent = false, _submitted = false, _picking = false;
  String? _photoError;
  bool get _current =>
      mounted &&
      ref.read(peopleScopeProvider) == widget.scope &&
      ref.read(caregiverCanManageProvider);
  @override
  void initState() {
    super.initState();
    Future.microtask(_recover);
  }

  Future<void> _recover() async {
    try {
      final photos = await ref.read(enrollmentPhotoPickerProvider).recover();
      if (_current && photos.isNotEmpty && _photos.isEmpty) {
        setState(() => _photos.addAll(photos.take(5)));
      }
    } catch (_) {
      if (_current) setState(() => _photoError = 'PICK_FAILED');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    for (final photo in _photos) {
      _evictPreview(photo);
    }
    _photos.clear();
    super.dispose();
  }

  void _evictPreview(EnrollmentPhoto photo) {
    unawaited(
      ResizeImage(
        MemoryImage(photo.bytes),
        width: 240,
      ).evict().then<void>((_) {}, onError: (Object _) {}),
    );
  }

  Future<void> _choose(int index) async {
    if (_picking) return;
    final s = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(s.personCamera),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.personGallery),
              onTap: () => Navigator.pop(context, 1),
            ),
            if (index < _photos.length)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(s.personRemovePhoto),
                onTap: () => Navigator.pop(context, 2),
              ),
          ],
        ),
      ),
    );
    if (!_current || choice == null) return;
    if (choice == 2) {
      ref.read(personEnrollmentProvider(widget.scope).notifier).clearFailure();
      setState(() {
        _evictPreview(_photos.removeAt(index));
        _photoError = null;
      });
      return;
    }
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final photo = await ref
          .read(enrollmentPhotoPickerProvider)
          .pick(camera: choice == 0);
      if (!_current || photo == null) return;
      ref.read(personEnrollmentProvider(widget.scope).notifier).clearFailure();
      setState(() {
        if (index < _photos.length) {
          _evictPreview(_photos[index]);
          _photos[index] = photo;
        } else if (_photos.length < 5) {
          _photos.add(photo);
        }
      });
    } catch (error) {
      if (_current) {
        setState(
          () => _photoError = error is PhotoSelectionFailure
              ? error.code
              : 'PICK_FAILED',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final draft = PersonEnrollment(
      name: _name.text,
      relationship: _relationship.text,
      consent: _consent,
      photos: _photos,
    );
    if (!draft.valid) return;
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(personEnrollmentProvider(widget.scope).notifier)
        .save(draft);
    if (mounted && _current && saved) {
      context.goNamed(RemoriScreen.c3.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(personEnrollmentProvider(widget.scope));
    final locked = state.busy || state.created || _picking;
    final badSlots = <int>{};
    for (final detail in state.failure?.details ?? <ApiFieldError>[]) {
      final match = RegExp(r'^body\.photos\.(\d+)$').firstMatch(detail.field);
      if (match != null) badSlots.add(int.parse(match.group(1)!));
    }
    final photoError = _photoError == 'PHOTO_TOO_LARGE'
        ? s.personPhotoTooLarge
        : _photoError == 'UNSUPPORTED_PHOTO'
        ? s.personPhotoUnsupported
        : _photoError != null
        ? s.personPhotoPickFailed
        : _submitted && _photos.isEmpty
        ? s.personPhotosRequired
        : null;
    return PopScope(
      canPop: !state.busy && !_picking,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, state.busy || _picking),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 32).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.personPhotos,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final slotSize = ((constraints.maxWidth - 72) / 5)
                                  .clamp(44.0, 58.0);
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var i = 0; i < 5; i++)
                                    Semantics(
                                      label: s.personPhotoSlot(i + 1),
                                      button: true,
                                      child: InkWell(
                                        onTap: locked
                                            ? null
                                            : () => _choose(
                                                i < _photos.length
                                                    ? i
                                                    : _photos.length,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: CustomPaint(
                                          foregroundPainter: _SlotBorder(
                                            bad: badSlots.contains(i),
                                            empty: i >= _photos.length,
                                          ),
                                          child: SizedBox(
                                            width: slotSize,
                                            height: slotSize,
                                            child: i < _photos.length
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.memory(
                                                      _photos[i].bytes,
                                                      fit: BoxFit.cover,
                                                      cacheWidth: 240,
                                                      errorBuilder: (_, _, _) =>
                                                          const Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                          ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.add,
                                                    size: 22,
                                                    color: RemoriColors.muted,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (photoError != null) _error(photoError),
                          for (final index in badSlots.where(
                            (i) => i >= 0 && i < _photos.length,
                          ))
                            _error(s.personPhotoInvalid(index + 1)),
                          const SizedBox(height: 8),
                          Text(
                            s.personPhotoTip,
                            style: const TextStyle(
                              fontSize: 13,
                              color: RemoriColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _field(
                            s.personName,
                            s.personNameHint,
                            _name,
                            80,
                            locked,
                            _submitted &&
                                        (_name.text.trim().isEmpty ||
                                            _name.text.trim().runes.length >
                                                80) ||
                                    _hasFieldError(state, 'name')
                                ? s.signupCheckFields
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            s.personRelationship,
                            s.personRelationshipHint,
                            _relationship,
                            40,
                            locked,
                            _submitted &&
                                        (_relationship.text.trim().isEmpty ||
                                            _relationship.text
                                                    .trim()
                                                    .runes
                                                    .length >
                                                40) ||
                                    _hasFieldError(state, 'relationship')
                                ? s.signupCheckFields
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 24,
                                child: Checkbox(
                                  value: _consent,
                                  semanticLabel: s.personConsent,
                                  side: const BorderSide(
                                    color: RemoriColors.purple,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: locked
                                      ? null
                                      : (value) =>
                                            setState(() => _consent = value!),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.personConsent,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if ((_submitted && !_consent) ||
                              state.failure?.code == 'CONSENT_REQUIRED')
                            _error(s.personConsentRequired),
                          if (state.failure != null)
                            _error(
                              state.created
                                  ? s.personCacheRetry
                                  : state.failure!.kind ==
                                            ApiFailureKind.network ||
                                        state.failure!.kind ==
                                            ApiFailureKind.timeout ||
                                        state.failure!.kind ==
                                            ApiFailureKind.invalidResponse
                                  ? s.personSaveUncertain
                                  : s.personSaveRetry,
                            ),
                          const SizedBox(height: 20),
                          const Spacer(),
                          RemoriButton(
                            label: state.busy ? s.personSaving : s.personSave,
                            onPressed: state.busy || _picking ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasFieldError(PersonEnrollmentState state, String field) =>
      state.failure?.details.any(
        (e) => e.field == 'body.$field' || e.field == field,
      ) ??
      false;
  Widget _error(String message) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      message,
      style: const TextStyle(fontSize: 13, color: RemoriColors.dangerInk),
      semanticsLabel: message,
    ),
  );
  Widget _field(
    String label,
    String hint,
    TextEditingController controller,
    int limit,
    bool locked,
    String? error,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        enabled: !locked,
        maxLength: limit,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          errorText: error,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    ],
  );
}

class _SlotBorder extends CustomPainter {
  const _SlotBorder({required this.bad, required this.empty});
  final bool bad, empty;
  @override
  void paint(Canvas canvas, Size size) {
    if (!bad && !empty) return;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bad ? 2.5 : 1.5
      ..color = bad ? RemoriColors.dangerInk : const Color(0xFF9AA6B2);
    if (bad) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 6) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 3).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SlotBorder old) => old.bad != bad || old.empty != empty;
}
