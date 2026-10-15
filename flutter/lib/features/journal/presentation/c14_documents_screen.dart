import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/document_data.dart';
import 'documents_providers.dart';
import 'journal_providers.dart';

class C14DocumentsScreen extends ConsumerStatefulWidget {
  const C14DocumentsScreen({super.key});
  @override
  ConsumerState<C14DocumentsScreen> createState() => _C14DocumentsScreenState();
}

class _C14DocumentsScreenState extends ConsumerState<C14DocumentsScreen>
    with WidgetsBindingObserver {
  bool _visible = true, _foreground = true;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _visible) {
      ref.read(documentsControllerProvider.notifier).refresh();
    } else {
      ref.read(documentsControllerProvider.notifier).hidePreviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        final c = ref.read(documentsControllerProvider.notifier);
        if (_visible && _foreground) {
          c.refresh();
        } else {
          c.hidePreviews();
        }
      });
    }
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode;
    final key = ref.watch(documentsKeyProvider),
        filter = ref.watch(documentsFilterProvider),
        state = ref.watch(documentsControllerProvider),
        snapshot = ref.watch(documentsDataProvider);
    final data = key == null || snapshot.isLoading || snapshot.hasError
        ? const DocumentsData()
        : snapshot.value ?? const DocumentsData();
    final names = [
      s.documentsAll,
      s.documentsReceipts,
      s.documentsBills,
      s.documentsMedicationLabels,
    ];
    String type(String value) => switch (value) {
      'receipt' => s.documentsReceipt,
      'bill' => s.documentsBill,
      'medication_label' => s.documentsMedicationLabel,
      _ => s.documentsOther,
    };
    Widget card(DocumentCard d) => Semantics(
      button: true,
      enabled: false,
      child: Container(
        key: ValueKey('document-${d.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: RemoriColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RemoriColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.title?.trim().isNotEmpty == true ? d.title! : type(d.type),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: ['Readex Pro'],
                  ),
                ),
                Text(
                  '${type(d.type)} · ${DateFormat('EEE d MMM, HH:mm', locale).format(PatientTime.local(d.capturedAt, key!.$1.timezone))}',
                  style: _sub,
                ),
                if (MediaQuery.textScalerOf(context).scale(15) > 22 &&
                    d.headline != null)
                  Text(
                    d.headline!,
                    style: _headline,
                    textDirection: Bidi.detectRtlDirectionality(d.headline!)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
              ],
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DocumentPreview(
                  key: ValueKey(
                    '${key.$1.caregiverId}:${key.$1.patientId}:${filter.name}:${d.id}:${state.revision}',
                  ),
                  owner: key,
                  document: d,
                  allowed:
                      _visible && _foreground && state.previews && !state.busy,
                ),
                const SizedBox(width: 12),
                Expanded(child: content),
                if (MediaQuery.textScalerOf(context).scale(15) <= 22 &&
                    d.headline != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .4,
                    ),
                    child: Text(
                      d.headline!,
                      style: _headline,
                      textDirection: Bidi.detectRtlDirectionality(d.headline!)
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
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
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left, size: 26),
                    onPressed: () => context.goNamed(RemoriScreen.c18.name),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.documentsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification is ScrollUpdateNotification &&
                    notification.metrics.extentAfter < 200 &&
                    data.hasMore &&
                    !state.busy &&
                    !state.failed) {
                  Future.microtask(() {
                    if (mounted && key == ref.read(documentsKeyProvider)) {
                      ref
                          .read(documentsControllerProvider.notifier)
                          .refresh(more: true);
                    }
                  });
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(documentsControllerProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in DocumentFilter.values)
                          Semantics(
                            button: true,
                            selected: filter == f,
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(documentsFilterProvider.notifier)
                                  .select(f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: filter == f
                                      ? RemoriColors.purple
                                      : RemoriColors.surface,
                                  border: Border.all(
                                    color: RemoriColors.purple,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Text(
                                  names[f.index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: filter == f
                                        ? RemoriColors.surface
                                        : RemoriColors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.documentsIntro, style: _sub),
                    const SizedBox(height: 12),
                    if (state.failed || snapshot.hasError) ...[
                      Text(
                        data.documents.isEmpty
                            ? s.documentsLoadFailed
                            : s.documentsOffline,
                        style: _sub,
                      ),
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () => ref
                                  .read(documentsControllerProvider.notifier)
                                  .refresh(more: state.moreFailed),
                        child: Text(s.homeRetry),
                      ),
                    ],
                    if (data.documents.isEmpty &&
                        (state.busy || snapshot.isLoading))
                      const Center(child: CircularProgressIndicator())
                    else if (key == null)
                      Text(s.documentsUnavailable, style: _sub)
                    else if (data.documents.isEmpty)
                      Text(s.documentsEmpty, style: _sub),
                    for (final d in data.documents)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card(d),
                      ),
                    if (state.busy && data.documents.isNotEmpty)
                      const Center(child: CircularProgressIndicator()),
                    if (data.documents.isNotEmpty)
                      Text(s.documentsDetailPending, style: _sub),
                  ],
                ),
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
const _headline = TextStyle(
  fontFamily: 'Manrope',
  fontFamilyFallback: ['Readex Pro'],
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: RemoriColors.purple,
);

class _DocumentPreview extends ConsumerWidget {
  const _DocumentPreview({
    super.key,
    required this.owner,
    required this.document,
    required this.allowed,
  });
  final DocumentsKey owner;
  final DocumentCard document;
  final bool allowed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context), photo = document.preview();
    final live =
        photo != null &&
        (ref.watch(documentsPreviewLiveProvider((owner, document))).value ??
            photo.available(ref.watch(journalClockProvider)()));
    Widget placeholder() => Semantics(
      label: s.documentsPreviewUnavailable,
      child: const ColoredBox(
        color: RemoriColors.lavender,
        child: Center(
          child: Icon(
            Icons.description_outlined,
            color: RemoriColors.purple,
            size: 28,
          ),
        ),
      ),
    );
    return SizedBox(
      width: 56,
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: !allowed || !live
            ? placeholder()
            : FutureBuilder<Uint8List>(
                future: ref.watch(documentsPreviewsProvider(owner)).load(photo),
                builder: (context, value) {
                  if (value.error case final Object error) {
                    Future.microtask(() {
                      if (context.mounted) {
                        ref
                            .read(documentsControllerProvider.notifier)
                            .photoFailed(owner, document.id, error);
                      }
                    });
                  }
                  return value.data == null
                      ? placeholder()
                      : Image.memory(
                          value.data!,
                          fit: BoxFit.cover,
                          semanticLabel: s.documentsPreview,
                          errorBuilder: (_, _, _) => placeholder(),
                        );
                },
              ),
      ),
    );
  }
}
