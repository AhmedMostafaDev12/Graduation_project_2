import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import 'auth_providers.dart';

class A3SignupScreen extends ConsumerStatefulWidget {
  const A3SignupScreen({super.key});
  @override
  ConsumerState<A3SignupScreen> createState() => _A3SignupScreenState();
}

class _A3SignupScreenState extends ConsumerState<A3SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _obscured = true;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _signUp() async {
    final state = ref.read(signUpControllerProvider);
    if (state.busy || state.accountCreated) return;
    setState(() => _submitted = true);
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8 ||
        _password.text.length > 128) {
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(signUpControllerProvider.notifier)
        .signUp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
    if (mounted && success) {
      _password.clear();
      context.goNamed(RemoriScreen.a4.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signUpControllerProvider);
    final failure = state.failure;
    final error = state.accountCreated
        ? s.signupAccountCreated
        : failure?.code == 'EMAIL_TAKEN'
        ? s.signupEmailTaken
        : failure?.code == 'VALIDATION_ERROR'
        ? s.signupCheckFields
        : failure?.kind == ApiFailureKind.network ||
              failure?.kind == ApiFailureKind.timeout
        ? s.loginConnectionError
        : s.signupRetry;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 11,
          children: [
            Column(
              children: [
                RemoriLogo(semanticLabel: s.appName, width: 120),
                const SizedBox(height: 6),
                Text(
                  s.signupTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge!.copyWith(height: 1.35),
                ),
              ],
            ),
            _field(
              s.fullNameLabel,
              _name,
              hint: s.fullNameHint,
              autofill: AutofillHints.name,
            ),
            _field(
              s.emailLabel,
              _email,
              hint: s.emailHint,
              autofill: AutofillHints.username,
              type: TextInputType.emailAddress,
              asset: 'assets/images/login-email.svg',
              ltr: true,
            ),
            _field(
              s.phoneLabel,
              _phone,
              hint: s.phoneHint,
              autofill: AutofillHints.telephoneNumber,
              type: TextInputType.phone,
              optional: true,
              ltr: true,
            ),
            _field(
              s.passwordLabel,
              _password,
              hint: s.passwordHint,
              autofill: AutofillHints.newPassword,
              type: TextInputType.visiblePassword,
              asset: 'assets/images/login-password.svg',
              password: true,
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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: RemoriButton(
                label: state.busy ? s.signingUp : s.signUp,
                onPressed: state.busy || state.accountCreated ? null : _signUp,
              ),
            ),
            Row(
              spacing: 12,
              children: [
                const Expanded(
                  child: Divider(height: 1, color: Color(0x33000000)),
                ),
                Text(s.orLabel, style: theme.textTheme.bodySmall),
                const Expanded(
                  child: Divider(height: 1, color: Color(0x33000000)),
                ),
              ],
            ),
            _social(s.continueGoogle, 'assets/images/google.svg'),
            _social(s.continueFacebook, 'assets/images/facebook.svg'),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  s.alreadyAccount,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: state.busy
                        ? null
                        : () => context.goNamed(RemoriScreen.a2.name),
                    child: Text(
                      s.signupLogIn,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: RemoriColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String hint,
    required String autofill,
    TextInputType type = TextInputType.text,
    String? asset,
    bool optional = false,
    bool password = false,
    bool ltr = false,
  }) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signUpControllerProvider);
    String? error;
    if (_submitted) {
      if (!optional &&
          (password
              ? controller.text.isEmpty
              : controller.text.trim().isEmpty)) {
        error = s.requiredField;
      } else if (password &&
          (controller.text.length < 8 || controller.text.length > 128)) {
        error = s.signupPasswordLength;
      }
    }
    if (state.failure?.code == 'VALIDATION_ERROR') {
      final field = identical(controller, _name)
          ? 'full_name'
          : identical(controller, _email)
          ? 'email'
          : identical(controller, _phone)
          ? 'phone'
          : 'password';
      if (state.failure!.details.any(
        (detail) => detail.field.split('.').last == field,
      )) {
        error = s.signupInvalidField;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium!.copyWith(
            fontFamily: Localizations.localeOf(context).languageCode == 'ar'
                ? 'Readex Pro'
                : 'Manrope',
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            enabled: !state.busy && !state.accountCreated,
            obscureText: password && _obscured,
            textDirection: ltr ? TextDirection.ltr : null,
            autocorrect: false,
            enableSuggestions: !password,
            keyboardType: type,
            autofillHints: [autofill],
            textInputAction: password
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: password ? (_) => _signUp() : null,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintTextDirection: type == TextInputType.phone
                  ? TextDirection.ltr
                  : null,
              errorText: error,
              hintStyle: theme.textTheme.bodyMedium!.copyWith(
                color: const Color(0x80000000),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
              prefixIcon: asset == null
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 12,
                      ),
                      child: SvgPicture.asset(
                        asset,
                        width: 20,
                        height: 20,
                        excludeFromSemantics: true,
                      ),
                    ),
              suffixIcon: !password
                  ? null
                  : IconButton(
                      tooltip: _obscured ? s.showPassword : s.hidePassword,
                      onPressed: state.busy || state.accountCreated
                          ? null
                          : () => setState(() => _obscured = !_obscured),
                      icon: SvgPicture.asset(
                        'assets/images/login-eye.svg',
                        width: 20,
                        height: 20,
                        excludeFromSemantics: true,
                      ),
                    ),
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

  Widget _social(String label, String asset) => OutlinedButton(
    onPressed: null,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      side: const WidgetStatePropertyAll(BorderSide(color: Color(0x47000000))),
      backgroundColor: const WidgetStatePropertyAll(RemoriColors.surface),
      foregroundColor: const WidgetStatePropertyAll(Color(0x80000000)),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.bodyMedium!
            .copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: .5,
          child: SvgPicture.asset(
            asset,
            width: 22,
            height: 22,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
