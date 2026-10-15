import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import 'place_editor_providers.dart';
import 'place_map.dart';
import 'places_providers.dart';

class C11EditPlaceScreen extends ConsumerWidget {
  const C11EditPlaceScreen({super.key, this.patientId, this.placeId});
  final String? patientId, placeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(placesScopeProvider);
    if (scope == null ||
        scope.patientId != patientId ||
        !ref.watch(caregiverCanManageProvider) ||
        placeId?.isEmpty == true) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, false),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).placeUnavailable),
            ),
          ],
        ),
      );
    }
    final editor = (scope, placeId);
    return _PlaceForm(key: ValueKey(editor), editor: editor);
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
          padding: EdgeInsets.zero,
          onPressed: busy ? null : () => context.goNamed(RemoriScreen.c10.name),
          icon: const Icon(Icons.chevron_left, size: 26),
        ),
      ),
      Expanded(
        child: Text(
          AppLocalizations.of(context).placeEditTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  ),
);

class _PlaceForm extends ConsumerStatefulWidget {
  const _PlaceForm({super.key, required this.editor});
  final PlaceEditorKey editor;
  @override
  ConsumerState<_PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends ConsumerState<_PlaceForm> {
  final _name = TextEditingController();
  bool _submitted = false, _confirming = false;
  bool get _current =>
      mounted && ref.read(placesScopeProvider) == widget.editor.$1;
  PlaceEditor get _controller =>
      ref.read(placeEditorProvider(widget.editor).notifier);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    // Let focus/field semantics settle before the route changes on a fast API.
    await WidgetsBinding.instance.endOfFrame;
    if (!_current) return;
    final saved = await _controller.write();
    if (mounted && _current && saved) context.goNamed(RemoriScreen.c10.name);
  }

  Future<void> _delete() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.placeDelete),
        content: Text(s.placeDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.detailCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.placeDelete),
          ),
        ],
      ),
    );
    if (!_current) return;
    setState(() => _confirming = false);
    if (confirmed != true || !ref.read(caregiverCanManageProvider)) return;
    final removed = await _controller.write(delete: true);
    if (mounted && _current && removed) context.goNamed(RemoriScreen.c10.name);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        state = ref.watch(placeEditorProvider(widget.editor));
    final draft = state.draft;
    if (_name.text != draft.name) {
      _name.value = TextEditingValue(
        text: draft.name,
        selection: TextSelection.collapsed(offset: draft.name.length),
      );
    }
    final locked =
        state.busy ||
        state.loading ||
        state.acknowledged ||
        state.uncertain ||
        state.missing ||
        _confirming;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    return PopScope(
      canPop: !state.busy,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, state.busy),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 28).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.loading)
                              const Center(child: CircularProgressIndicator())
                            else if (state.missing)
                              Text(s.placeUnavailable)
                            else ...[
                              SizedBox(
                                height: 320,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: ref.watch(placeMapBuilderProvider)(
                                    context,
                                    draft,
                                    locked,
                                    (point) => _controller.change(point: point),
                                  ),
                                ),
                              ),
                              if (state.locating)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(s.placeLocating, style: _small),
                                ),
                              if (!state.locating && draft.point == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    s.placeSelectPoint,
                                    style: _small,
                                  ),
                                ),
                              const SizedBox(height: 14),
                              Text(
                                s.placeName,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Semantics(
                                container: true,
                                label: s.placeName,
                                child: TextField(
                                  controller: _name,
                                  readOnly: locked,
                                  enableInteractiveSelection: !locked,
                                  onChanged: (name) =>
                                      _controller.change(name: name),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamilyFallback: ['Readex Pro'],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: s.placeNameHint,
                                    errorText:
                                        _submitted &&
                                            (draft.name.trim().isEmpty ||
                                                draft.name.trim().runes.length >
                                                    80)
                                        ? s.placeNameRequired
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.placeRadiusLabel(
                                  number.format(draft.radiusM),
                                ),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Slider(
                                value: draft.radiusM.clamp(50, 500).toDouble(),
                                min: 50,
                                max: 500,
                                divisions: 45,
                                activeColor: RemoriColors.purple,
                                inactiveColor: RemoriColors.lavender,
                                semanticFormatterCallback: (value) => s
                                    .placesRadius(number.format(value.round())),
                                onChanged: locked
                                    ? null
                                    : (value) => _controller.change(
                                        radiusM: value.round(),
                                      ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(s.placeRadiusMinimum, style: _small),
                                  Text(s.placeRadiusMaximum, style: _small),
                                ],
                              ),
                              if (!draft.sliderCompatible)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    s.placeRadiusPreserved,
                                    style: _small,
                                  ),
                                ),
                            ],
                            if (state.offline)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(s.placesOffline, style: _small),
                              ),
                            if (state.failure != null || state.uncertain) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.acknowledged
                                    ? s.placeCacheRetry
                                    : state.uncertain
                                    ? s.placeWriteUncertain
                                    : s.placeWriteFailed,
                                style: _small,
                              ),
                              if (state.acknowledged)
                                TextButton(
                                  onPressed: state.busy ? null : () => _save(),
                                  child: Text(s.homeRetry),
                                ),
                            ],
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            if (!state.missing && !state.loading) ...[
                              RemoriButton(
                                label: state.busy
                                    ? s.personSaving
                                    : s.placeSave,
                                onPressed: locked ? null : _save,
                              ),
                              if (widget.editor.$2 != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: locked ? null : _delete,
                                  child: Text(
                                    s.placeDelete,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: RemoriColors.dangerInk,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ],
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
}

const _small = TextStyle(fontSize: 13, height: 1.3, color: RemoriColors.muted);
