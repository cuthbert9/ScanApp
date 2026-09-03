import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../application/auth_controller.dart';

/// Operator sign-in.
///
/// A stub: no credentials are validated and nothing is stored. It exists so the
/// route guard, the navigation flow and the form layout are real from day one —
/// wiring real auth later is a change inside [AuthController], not here.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers are why this is a StatefulWidget rather than a ConsumerWidget.
  final TextEditingController _operatorId = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  @override
  void dispose() {
    _operatorId.dispose();
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() => ref.read(authControllerProvider.notifier).signIn();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

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
              Icon(
                Icons.local_shipping_outlined,
                size: context.sizes.iconXl,
                color: colors.onHeaderMuted,
              ),
              SizedBox(height: spacing.lg),
              Text(
                'scanapp',
                style: context.type.headingLg.copyWith(color: colors.onHeader),
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
              TextField(
                controller: _operatorId,
                decoration: const InputDecoration(labelText: 'Operator ID'),
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onSubmitted: (_) => _pinFocus.requestFocus(),
              ),
              SizedBox(height: spacing.md),
              TextField(
                controller: _pin,
                focusNode: _pinFocus,
                decoration: const InputDecoration(labelText: 'PIN'),
                obscureText: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                // Submitting from the keyboard matters: the device has a
                // physical keypad and the operator may never touch the screen.
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: spacing.xl),
              FilledButton(onPressed: _submit, child: const Text('Sign in')),
              SizedBox(height: spacing.md),
              Text(
                'Any credentials are accepted while sign-in is a stub.',
                style: context.type.caption.copyWith(
                  color: colors.onHeaderMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
