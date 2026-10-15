import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../domain/caregivers_data.dart';
import 'caregivers_providers.dart';
import 'home_providers.dart';

class C19CaregiversScreen extends ConsumerWidget {
  const C19CaregiversScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(caregiversScopeProvider);
    return scope == null
        ? SafeArea(
            child: Column(
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context).caregiversUnavailable,
                  ),
                ),
              ],
            ),
          )
        : _Caregivers(key: ValueKey(scope), scope: scope);
  }
}

Widget _header(BuildContext context) => Container(
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
          padding: EdgeInsets.zero,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.chevron_left, size: 26),
          onPressed: () => context.goNamed(RemoriScreen.c18.name),
        ),
      ),
      Expanded(
        child: Text(
          AppLocalizations.of(context).moreCaregivers,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  ),
);

class _Caregivers extends ConsumerStatefulWidget {
  const _Caregivers({super.key, required this.scope});
  final CaregiversScope scope;
  @override
  ConsumerState<_Caregivers> createState() => _CaregiversState();
}

class _CaregiversState extends ConsumerState<_Caregivers>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _relationship = TextEditingController();
  String _permission = 'viewer';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _relationship.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(caregiversControllerProvider(widget.scope).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope, s = AppLocalizations.of(context);
    final state = ref.watch(caregiversControllerProvider(scope)),
        snapshot = ref.watch(caregiversDataProvider(scope));
    final data = snapshot.isLoading || snapshot.hasError
        ? const CaregiversData()
        : snapshot.value ?? const CaregiversData();
    final manager = ref.watch(caregiverCanManageProvider);
    final enabled =
        manager && !state.busy && !state.pending && !state.uncertain;
    ref.listen(caregiversControllerProvider(scope), (old, next) {
      if (next.successes > (old?.successes ?? 0)) {
        _email.clear();
        _relationship.clear();
        setState(() => _permission = 'viewer');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.caregiversAdded)));
      }
    });
    String role(String permission) =>
        permission == 'manager' ? s.caregiversManager : s.caregiversViewer;
    Widget chip(String label, {bool selected = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? RemoriColors.purple : RemoriColors.surface,
        border: Border.all(color: RemoriColors.purple),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : RemoriColors.purple,
        ),
      ),
    );
    Widget card(LinkedCaregiver person) {
      final words = person.name.trim().split(RegExp(r'\s+'));
      final initials = words
          .take(2)
          .map((word) => word.characters.first)
          .join();
      final details = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person.userId == scope.$1
                ? s.caregiversYou(person.name)
                : person.name,
            style: _title,
          ),
          const SizedBox(height: 2),
          Text(person.relationship, style: _sub),
        ],
      );
      final badges = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (person.primary) chip(s.caregiversPrimary),
          chip(
            role(person.permission),
            selected: person.permission == 'manager',
          ),
        ],
      );
      return _card(
        LayoutBuilder(
          builder: (context, constraints) {
            final large = MediaQuery.textScalerOf(context).scale(15) > 22;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: RemoriColors.lavender,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      color: RemoriColors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: large
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            details,
                            const SizedBox(height: 8),
                            badges,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 8),
                            badges,
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      );
    }

    String failure() {
      if (state.pending) return s.caregiversPending;
      if (state.uncertain) return s.caregiversUncertain;
      return switch (state.failure?.code) {
        'CAREGIVER_NOT_FOUND' => s.caregiversNotFound,
        'ALREADY_LINKED' => s.caregiversAlreadyLinked,
        'MANAGER_ONLY' => s.caregiversManagerOnly,
        _ => s.caregiversOffline,
      };
    }

    return SafeArea(
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(caregiversControllerProvider(scope).notifier)
                  .refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.busy) const LinearProgressIndicator(),
                  if (state.failure != null || snapshot.hasError) ...[
                    Text(failure(), style: _sub),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(
                                  caregiversControllerProvider(scope).notifier,
                                )
                                .refresh(),
                      child: Text(s.homeRetry),
                    ),
                  ],
                  for (final person in data.links) ...[
                    card(person),
                    const SizedBox(height: 12),
                  ],
                  if (data.links.isEmpty && !state.busy) ...[
                    Text(
                      state.failure == null && !snapshot.hasError
                          ? s.caregiversEmpty
                          : s.caregiversListUnavailable,
                      style: _sub,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(s.caregiversPermissionHelp, style: _sub),
                  if (manager) ...[
                    const SizedBox(height: 12),
                    _card(
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(s.caregiversAddTitle, style: _title),
                            const SizedBox(height: 10),
                            Text(s.caregiversExistingAccountHelp, style: _sub),
                            const SizedBox(height: 10),
                            Text(s.caregiversEmail, style: _label),
                            const SizedBox(height: 4),
                            TextFormField(
                              key: const Key('caregiver-email'),
                              controller: _email,
                              enabled: enabled,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              decoration: InputDecoration(
                                hintText: s.caregiversEmailHint,
                              ),
                              validator: (value) =>
                                  CaregiverLinkDraft(
                                    email: value ?? '',
                                    relationship: 'x',
                                  ).isValid
                                  ? null
                                  : s.caregiversEmailInvalid,
                            ),
                            const SizedBox(height: 10),
                            Text(s.caregiversRelationship, style: _label),
                            const SizedBox(height: 4),
                            TextFormField(
                              key: const Key('caregiver-relationship'),
                              controller: _relationship,
                              enabled: enabled,
                              maxLength: 60,
                              decoration: InputDecoration(
                                hintText: s.caregiversRelationshipHint,
                                counterText: '',
                              ),
                              validator: (value) =>
                                  value?.trim().isNotEmpty == true
                                  ? null
                                  : s.caregiversRelationshipInvalid,
                            ),
                            const SizedBox(height: 10),
                            Text(s.caregiversPermission, style: _label),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final permission in ['viewer', 'manager'])
                                  Semantics(
                                    selected: _permission == permission,
                                    button: true,
                                    enabled: enabled,
                                    child: InkWell(
                                      onTap: enabled
                                          ? () => setState(
                                              () => _permission = permission,
                                            )
                                          : null,
                                      child: chip(
                                        role(permission),
                                        selected: _permission == permission,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            RemoriButton(
                              label: s.caregiversAdd,
                              onPressed: enabled
                                  ? () {
                                      if (_form.currentState!.validate()) {
                                        ref
                                            .read(
                                              caregiversControllerProvider(
                                                scope,
                                              ).notifier,
                                            )
                                            .link(
                                              CaregiverLinkDraft(
                                                email: _email.text.trim(),
                                                relationship: _relationship.text
                                                    .trim(),
                                                permission: _permission,
                                              ),
                                            );
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
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

Widget _card(Widget child) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  decoration: BoxDecoration(
    color: RemoriColors.surface,
    border: Border.all(color: RemoriColors.border),
    borderRadius: BorderRadius.circular(10),
  ),
  child: child,
);
const _title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
const _sub = TextStyle(
  fontSize: 13,
  height: 1.3,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);
const _label = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  fontFamily: 'Manrope',
  fontFamilyFallback: ['Readex Pro'],
);
