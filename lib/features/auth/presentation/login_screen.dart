import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../application/auth_controller.dart';
import '../domain/session.dart';

/// Operator sign-in against the ERP's general auth endpoint.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers are why this is a StatefulWidget rather than a ConsumerWidget.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    // Guarded here rather than by nulling the button's `onPressed` — that
    // would drop it into the theme's *disabled* style (a washed-out grey),
    // which reads as "unavailable" rather than "working on it". A busy
    // button should stay fully coloured and just ignore a repeat tap.
    if (ref.read(authControllerProvider).isLoading) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;
    final AsyncValue<Session?> auth = ref.watch(authControllerProvider);

    // Surfaces a rejected sign-in once, right as it happens — not on every
    // rebuild the error state survives through.
    ref.listen<AsyncValue<Session?>>(authControllerProvider, (
      AsyncValue<Session?>? previous,
      AsyncValue<Session?> next,
    ) {
      if (next.hasError && previous?.isLoading == true) {
        final Object error = next.error!;
        final String message = error is AppException
            ? error.message
            : 'Sign-in failed.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      backgroundColor: colors.headerSurface,
      // The keyboard covers roughly half this screen, so the form must scroll
      // rather than be pushed off the bottom (CLAUDE.md rule 1c).
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xl,
            vertical: spacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // style-ok: one-off login wordmark — the app's only logotype,
              // wider-tracked than any token carries for actual body text.
              Text(
                'MSD',
                style: context.type.displayLg.copyWith(
                  color: colors.onHeader,
                  letterSpacing: 12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.xs),
              Text(
                'Dispatch & loading',
                style: context.type.overline.copyWith(
                  color: colors.onHeaderMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.xxl),
              // A caption above the field, not `InputDecoration.labelText` —
              // an outlined field's floated label sits on the border itself
              // with a cutout, which is not the static-above-the-box look
              // this screen wants. Same treatment as `ScanInputField`'s
              // label, coloured for this screen's navy background instead of
              // a light surface.
              Text(
                'EMAIL',
                style: context.type.overline.copyWith(
                  color: colors.onHeaderMuted,
                ),
              ),
              SizedBox(height: spacing.xs),
              TextField(
                controller: _email,
                decoration: const InputDecoration(hintText: 'Enter your email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              SizedBox(height: spacing.md),
              Text(
                'PASSWORD',
                style: context.type.overline.copyWith(
                  color: colors.onHeaderMuted,
                ),
              ),
              SizedBox(height: spacing.xs),
              TextField(
                controller: _password,
                focusNode: _passwordFocus,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                // Submitting from the keyboard matters: the device has a
                // physical keypad and the operator may never touch the screen.
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: spacing.xl),
              FilledButton(
                onPressed: _submit,
                child: AnimatedSwitcher(
                  duration: context.motion.feedback,
                  switchInCurve: context.motion.standardCurve,
                  switchOutCurve: context.motion.standardCurve,
                  child: auth.isLoading
                      ? SizedBox(
                          key: const ValueKey<String>('spinner'),
                          width: context.sizes.iconMd,
                          height: context.sizes.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: context.sizes.borderThick,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Text(key: ValueKey<String>('label'), 'Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
