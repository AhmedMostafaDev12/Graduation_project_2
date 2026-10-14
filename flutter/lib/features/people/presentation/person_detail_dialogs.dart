import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/enrollment_photo_picker.dart';
import '../domain/person_detail.dart';
import '../domain/person_enrollment.dart';
import 'people_providers.dart';
import 'person_detail_providers.dart';
import 'person_enrollment_providers.dart';

class PersonEditDialog extends ConsumerStatefulWidget {
  const PersonEditDialog({super.key, required this.scope, required this.data});
  final PersonDetailScope scope;
  final PersonDetailData data;
  @override
  ConsumerState<PersonEditDialog> createState() => _PersonEditDialogState();
}

class _PersonEditDialogState extends ConsumerState<PersonEditDialog> {
  late final _name = TextEditingController(text: widget.data.person.name);
  late final _relationship = TextEditingController(
    text: widget.data.person.relationship,
  );
  bool _submitted = false;
  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_name.text.trim().isEmpty ||
        _name.text.trim().runes.length > 80 ||
        _relationship.text.trim().isEmpty ||
        _relationship.text.trim().runes.length > 40) {
      return;
    }
    final saved = await ref
        .read(personDetailControllerProvider(widget.scope).notifier)
        .perform(
          PersonAction.edit,
          name: _name.text,
          relationship: _relationship.text,
        );
    if (mounted && saved) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(personDetailControllerProvider(widget.scope));
    final current = ref.watch(peopleScopeProvider) == widget.scope.owner;
    if (!current || !ref.watch(caregiverCanManageProvider)) {
      return _unavailable(context);
    }
    return PopScope(
      canPop: !state.busy,
      child: AlertDialog(
        title: Text(s.detailEdit),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                enabled: !state.busy && current,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: s.personName,
                  hintText: s.personNameHint,
                  errorText:
                      _submitted &&
                          (_name.text.trim().isEmpty ||
                              _name.text.trim().runes.length > 80)
                      ? s.signupCheckFields
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _relationship,
                enabled: !state.busy && current,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: s.personRelationship,
                  hintText: s.personRelationshipHint,
                  errorText:
                      _submitted &&
                          (_relationship.text.trim().isEmpty ||
                              _relationship.text.trim().runes.length > 40)
                      ? s.signupCheckFields
                      : null,
                ),
              ),
              if (state.failure != null)
                Text(detailFailureMessage(context, state)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.busy ? null : () => Navigator.pop(context),
            child: Text(s.detailCancel),
          ),
          FilledButton(
            onPressed: state.busy || !current ? null : _save,
            child: Text(state.busy ? s.personSaving : s.detailSave),
          ),
        ],
      ),
    );
  }
}

class PersonPhotosDialog extends ConsumerStatefulWidget {
  const PersonPhotosDialog({
    super.key,
    required this.scope,
    required this.capacity,
  });
  final PersonDetailScope scope;
  final int capacity;
  @override
  ConsumerState<PersonPhotosDialog> createState() => _PersonPhotosDialogState();
}

class _PersonPhotosDialogState extends ConsumerState<PersonPhotosDialog> {
  final _photos = <EnrollmentPhoto>[];
  bool _picking = false, _submitted = false;
  String? _problem;
  bool get _current =>
      mounted && ref.read(peopleScopeProvider) == widget.scope.owner;
  void _evict(EnrollmentPhoto photo) => unawaited(
    ResizeImage(
      MemoryImage(photo.bytes),
      width: 240,
    ).evict().then<void>((_) {}, onError: (Object _) {}),
  );
  @override
  void dispose() {
    for (final photo in _photos) {
      _evict(photo);
    }
    _photos.clear();
    super.dispose();
  }

  Future<void> _pick(int index) async {
    final s = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.personCamera),
              leading: const Icon(Icons.camera_alt_outlined),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              title: Text(s.personGallery),
              leading: const Icon(Icons.photo_library_outlined),
              onTap: () => Navigator.pop(context, 1),
            ),
            if (index < _photos.length)
              ListTile(
                title: Text(s.personRemovePhoto),
                leading: const Icon(Icons.delete_outline),
                onTap: () => Navigator.pop(context, 2),
              ),
          ],
        ),
      ),
    );
    if (!_current || choice == null) return;
    if (choice == 2) {
      ref
          .read(personDetailControllerProvider(widget.scope).notifier)
          .clearFailure();
      setState(() => _evict(_photos.removeAt(index)));
      return;
    }
    setState(() {
      _picking = true;
      _problem = null;
    });
    try {
      final photo = await ref
          .read(enrollmentPhotoPickerProvider)
          .pick(camera: choice == 0);
      if (!_current || photo == null) return;
      ref
          .read(personDetailControllerProvider(widget.scope).notifier)
          .clearFailure();
      setState(() {
        if (index < _photos.length) {
          _evict(_photos[index]);
          _photos[index] = photo;
        } else if (_photos.length < widget.capacity.clamp(0, 5)) {
          _photos.add(photo);
        }
      });
    } catch (error) {
      if (_current) {
        setState(
          () => _problem = error is PhotoSelectionFailure
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
    if (_photos.isEmpty) return;
    final saved = await ref
        .read(personDetailControllerProvider(widget.scope).notifier)
        .perform(PersonAction.addPhotos, photos: List.of(_photos));
    if (mounted && saved) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(personDetailControllerProvider(widget.scope));
    final current = ref.watch(peopleScopeProvider) == widget.scope.owner;
    if (!current || !ref.watch(caregiverCanManageProvider)) {
      return _unavailable(context);
    }
    final bad = <int>{};
    for (final detail in state.failure?.details ?? []) {
      final match = RegExp(r'^body\.photos\.(\d+)$').firstMatch(detail.field);
      if (match != null) bad.add(int.parse(match.group(1)!));
    }
    return PopScope(
      canPop: !state.busy && !_picking,
      child: AlertDialog(
        title: Text(s.detailAddPhotos),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.personPhotos),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < widget.capacity.clamp(0, 5); i++)
                    Semantics(
                      label: s.personPhotoSlot(i + 1),
                      button: true,
                      child: InkWell(
                        onTap: state.busy || _picking || !current
                            ? null
                            : () => _pick(
                                i < _photos.length ? i : _photos.length,
                              ),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: bad.contains(i)
                                  ? RemoriColors.dangerInk
                                  : RemoriColors.border,
                              width: bad.contains(i) ? 2.5 : 1,
                            ),
                          ),
                          child: i < _photos.length
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _photos[i].bytes,
                                    cacheWidth: 240,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                )
                              : const Icon(Icons.add),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.personPhotoTip),
              if (_submitted && _photos.isEmpty) Text(s.personPhotosRequired),
              if (_problem != null)
                Text(
                  _problem == 'PHOTO_TOO_LARGE'
                      ? s.personPhotoTooLarge
                      : _problem == 'UNSUPPORTED_PHOTO'
                      ? s.personPhotoUnsupported
                      : s.personPhotoPickFailed,
                ),
              for (final i in bad.where((i) => i >= 0 && i < _photos.length))
                Text(
                  s.personPhotoInvalid(i + 1),
                  style: const TextStyle(color: RemoriColors.dangerInk),
                ),
              if (state.failure != null)
                Text(detailFailureMessage(context, state)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.busy || _picking
                ? null
                : () => Navigator.pop(context),
            child: Text(s.detailCancel),
          ),
          FilledButton(
            onPressed: state.busy || _picking || !current ? null : _save,
            child: Text(state.busy ? s.personSaving : s.detailSavePhotos),
          ),
        ],
      ),
    );
  }
}

String detailFailureMessage(BuildContext context, PersonDetailState state) {
  final s = AppLocalizations.of(context);
  if (state.pending) return s.detailSavedRefresh;
  return switch (state.failure?.code) {
    'LAST_PHOTO' => s.detailLastPhoto,
    'TOO_MANY_PHOTOS' => s.detailTooManyPhotos,
    'PERSON_NOT_FOUND' || 'PHOTO_NOT_FOUND' => s.detailGone,
    'VALIDATION_ERROR' => s.signupCheckFields,
    _ => s.detailRetryMessage,
  };
}

Widget _unavailable(BuildContext context) => AlertDialog(
  content: Text(AppLocalizations.of(context).personUnavailable),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(AppLocalizations.of(context).detailCancel),
    ),
  ],
);
