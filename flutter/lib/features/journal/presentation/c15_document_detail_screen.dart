import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/document_detail.dart';
import 'document_detail_providers.dart';
import 'journal_providers.dart';

class C15DocumentDetailScreen extends ConsumerWidget {
  const C15DocumentDetailScreen({super.key, this.patientId, this.documentId});
  final String? patientId, documentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(journalScopeProvider),
        s = AppLocalizations.of(context);
    if (scope == null ||
        scope.patientId != patientId ||
        documentId == null ||
        documentId!.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, s.documentsTitle),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s.documentDetailUnavailable),
            ),
          ],
        ),
      );
    }
    final key = (scope, documentId!);
    return _Detail(key: ValueKey(key), owner: key);
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(RemoriScreen.c14.name);
  }
}

Widget _header(BuildContext context, String title) => Container(
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
          icon: const Icon(Icons.chevron_left, size: 26),
          onPressed: () => _back(context),
        ),
      ),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  ),
);

class _Detail extends ConsumerStatefulWidget {
  const _Detail({super.key, required this.owner});
  final DocumentDetailKey owner;
  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> with WidgetsBindingObserver {
  bool _visible = true, _foreground = true, _expanded = false;
  DocumentDetailController get _controller =>
      ref.read(documentDetailControllerProvider(widget.owner).notifier);
  @override
  void initState() {
    super.initState();
    final life = WidgetsBinding.instance.lifecycleState;
    _foreground = life == null || life == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState life) {
    setState(() => _foreground = life == AppLifecycleState.resumed);
    if (_foreground && _visible) {
      _controller.refresh();
    } else {
      _controller.hidePhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.owner,
        s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode;
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        if (_visible && _foreground) {
          _controller.refresh();
        } else {
          _controller.hidePhotos();
        }
      });
    }
    final state = ref.watch(documentDetailControllerProvider(key)),
        snapshot = ref.watch(documentDetailDataProvider(key));
    final detail = state.missing || snapshot.isLoading || snapshot.hasError
        ? null
        : snapshot.value;
    final live = ref.watch(documentDetailPhotoLiveProvider(key)).value ?? false;
    String type(String? v) => switch (v) {
      'receipt' => s.documentsReceipt,
      'bill' => s.documentsBill,
      'medication_label' => s.documentsMedicationLabel,
      _ => s.documentsOther,
    };
    String label(DocumentField f) =>
        f.label ??
        switch (f.key) {
          'total' => s.documentFieldAmount,
          'date' => s.documentFieldDate,
          'items' => s.documentFieldItems,
          'merchant' => s.documentFieldStore,
          'issuer' => s.documentFieldCompany,
          'due_date' => s.documentFieldDueDate,
          'medication_name' => s.documentFieldMedicine,
          'strength' => s.documentFieldStrength,
          'instructions' => s.documentFieldInstructions,
          'expiry_date' => s.documentFieldExpires,
          _ => s.documentsOther,
        };
    String value(DocumentField f) => f.type == 'date'
        ? DateFormat.yMMMd(locale).format(DateTime.parse(f.value))
        : f.value;
    Widget placeholder() => Container(
      color: RemoriColors.lavender,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: RemoriColors.purple,
            ),
            const SizedBox(height: 12),
            Text(
              s.documentDetailPhotoUnavailable,
              textAlign: TextAlign.center,
              style: _sub,
            ),
          ],
        ),
      ),
    );
    Widget photo() {
      final p = detail?.photo();
      if (p == null ||
          !live ||
          !state.previews ||
          state.busy ||
          !_visible ||
          !_foreground) {
        return placeholder();
      }
      return FutureBuilder<Uint8List>(
        key: ValueKey(state.revision),
        future: ref.watch(documentDetailPhotosProvider(key)).load(p),
        builder: (context, v) {
          if (v.error case final Object error) {
            Future.microtask(() {
              if (context.mounted) _controller.photoFailed(error);
            });
          }
          return v.data == null
              ? placeholder()
              : Image.memory(
                  v.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 260,
                  semanticLabel: s.documentDetailPhoto,
                  errorBuilder: (_, _, _) => placeholder(),
                );
        },
      );
    }

    return SafeArea(
      child: Column(
        children: [
          _header(
            context,
            detail?.title?.trim().isNotEmpty == true
                ? detail!.title!
                : detail == null
                ? s.documentsTitle
                : type(detail.type),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _controller.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  if (state.missing)
                    Text(s.documentDetailUnavailable, style: _sub)
                  else ...[
                    if (state.failed || snapshot.hasError) ...[
                      Text(s.documentDetailOffline, style: _sub),
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () => _controller.refresh(),
                        child: Text(s.homeRetry),
                      ),
                    ],
                    if (state.busy && detail == null)
                      const Center(child: CircularProgressIndicator()),
                    SizedBox(
                      height: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: photo(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (detail != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: RemoriColors.surface,
                              border: Border.all(color: RemoriColors.purple),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              type(detail.type),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: RemoriColors.purple,
                              ),
                            ),
                          ),
                          Text(
                            s.documentDetailCaptured(
                              DateFormat('EEE d MMM, HH:mm', locale).format(
                                PatientTime.local(
                                  detail.capturedAt,
                                  key.$1.timezone,
                                ),
                              ),
                            ),
                            style: _sub,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final f in detail.fields)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: RemoriColors.border),
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final name = Text(
                                label(f),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: RemoriColors.muted,
                                  fontFamilyFallback: ['Readex Pro'],
                                ),
                              );
                              final text = value(f);
                              final field = Text(
                                text,
                                textAlign:
                                    Directionality.of(context) ==
                                        TextDirection.rtl
                                    ? TextAlign.left
                                    : TextAlign.right,
                                textDirection:
                                    Bidi.detectRtlDirectionality(text)
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamilyFallback: ['Readex Pro'],
                                ),
                              );
                              return MediaQuery.textScalerOf(context)
                                          .scale(14) >
                                      21
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        name,
                                        const SizedBox(height: 6),
                                        field,
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: name),
                                        const SizedBox(width: 12),
                                        Expanded(child: field),
                                      ],
                                    );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Semantics(
                        button: true,
                        expanded: _expanded,
                        child: GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: RemoriColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _expanded
                                          ? Icons.arrow_drop_down
                                          : Icons.arrow_right,
                                      size: 18,
                                    ),
                                    Expanded(
                                      child: Text(
                                        s.documentDetailFullText,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_expanded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      detail.ocrText.isEmpty
                                          ? s.documentDetailNoText
                                          : detail.ocrText,
                                      textDirection:
                                          Bidi.detectRtlDirectionality(
                                            detail.ocrText,
                                          )
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      style: _sub,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _sub = TextStyle(
  fontSize: 13,
  height: 1.3,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);
