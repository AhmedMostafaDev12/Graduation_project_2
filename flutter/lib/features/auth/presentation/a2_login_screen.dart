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

class A2LoginScreen extends ConsumerStatefulWidget {
  const A2LoginScreen({super.key});
  @override
  ConsumerState<A2LoginScreen> createState() => _A2LoginScreenState();
}

class _A2LoginScreenState extends ConsumerState<A2LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login(RemoriScreen destination) async {
    if (ref.read(loginControllerProvider).isLoading) return;
    setState(() => _submitted = true);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(loginControllerProvider.notifier)
        .login(_email.text, _password.text);
    if (mounted && success) {
      _password.clear();
      context.goNamed(destination.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final login = ref.watch(loginControllerProvider);
    final busy = login.isLoading;
    final failure = login.error;
    final error = failure is ApiFailure && failure.code == 'INVALID_CREDENTIALS'
        ? s.loginInvalidCredentials
        : failure is ApiFailure &&
              (failure.kind == ApiFailureKind.network ||
                  failure.kind == ApiFailureKind.timeout)
        ? s.loginConnectionError
        : s.loginRetry;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Column(
              children: [
                RemoriLogo(semanticLabel: s.appName, width: 130),
                const SizedBox(height: 6),
                Text(
                  s.loginTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge!.copyWith(height: 1.35),
                ),
              ],
            ),
            _field(
              s.emailLabel,
              _email,
              hint: s.emailHint,

              email: true,
              busy: busy,
            ),
            _field(
              s.passwordLabel,
              _password,
              hint: s.passwordHint,

              busy: busy,
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
                label: busy ? s.loggingIn : s.logIn,
                onPressed: busy ? null : () => _login(RemoriScreen.c1),
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.patientPhoneSetup,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            RemoriButton(
              label: s.logInSetupPatient,
              onPressed: busy ? null : () => _login(RemoriScreen.a4),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  s.noAccount,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: busy
                        ? null
                        : () => context.goNamed(RemoriScreen.a3.name),
                    child: Text(
                      s.signUp,
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

    required bool busy,
    bool email = false,
  }) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium!.copyWith(
                  fontFamily:
                      Localizations.localeOf(context).languageCode == 'ar'
                      ? 'Readex Pro'
                      : 'Manrope',
                ),
              ),
            ),
            if (!email)
              Semantics(
                button: true,
                enabled: false,
                child: Text(
                  s.forgotPassword,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: RemoriColors.purple.withValues(alpha: .5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !busy,
          textDirection: email ? TextDirection.ltr : null,
          obscureText: !email && _obscured,
          autocorrect: false,
          enableSuggestions: email,
          keyboardType: email
              ? TextInputType.emailAddress
              : TextInputType.visiblePassword,
          autofillHints: [
            email ? AutofillHints.username : AutofillHints.password,
          ],
          textInputAction: email ? TextInputAction.next : TextInputAction.done,
          onSubmitted: email ? null : (_) => _login(RemoriScreen.c1),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium!.copyWith(
              color: const Color(0x80000000),
            ),
            errorText: _submitted && controller.text.trim().isEmpty
                ? s.requiredField
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 12),
              child: SvgPicture.asset(
                email
                    ? 'assets/images/login-email.svg'
                    : 'assets/images/login-password.svg',
                width: 20,
                height: 20,
                excludeFromSemantics: true,
              ),
            ),
            suffixIcon: email
                ? null
                : IconButton(
                    tooltip: _obscured ? s.showPassword : s.hidePassword,
                    onPressed: busy
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
