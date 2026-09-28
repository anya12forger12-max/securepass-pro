import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/features/login/presentation/providers/login_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  late final bool _isSetup =
      PreferencesStorage.instance.getString(AppConstants.loginPinKey) == null;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('securepass_login:$pin');
    return base64Encode(bytes);
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;
    if (_isSetup) {
      if (pin.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits.');
        return;
      }
      if (pin != _confirmController.text) {
        setState(() => _error = 'PINs do not match.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    if (_isSetup) {
      await PreferencesStorage.instance.setString(
        AppConstants.loginPinKey,
        _hashPin(pin),
      );
      if (!mounted) return;
      ref.read(loginStateProvider.notifier).authenticate();
      context.go('/home');
      return;
    }
    final stored = PreferencesStorage.instance.getString(
      AppConstants.loginPinKey,
    );
    final ok = stored != null && stored == _hashPin(pin);
    if (!mounted) return;
    if (ok) {
      ref.read(loginStateProvider.notifier).authenticate();
      context.go('/home');
      return;
    }
    setState(() {
      _busy = false;
      _error = 'Incorrect PIN. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSetup ? Icons.lock_open_outlined : Icons.lock_outline,
                  size: 72,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _isSetup ? 'Set Up Your PIN' : 'Welcome Back',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSetup
                      ? 'Create a PIN to secure your vault. You will need this PIN every time you open SecurePass Pro.'
                      : 'Enter your PIN to unlock SecurePass Pro.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'PIN input field',
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_isSetup) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Confirm PIN input field',
                    child: TextField(
                      controller: _confirmController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Error message',
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Semantics(
                  label: _isSetup ? 'Set PIN button' : 'Unlock button',
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSetup ? 'Set PIN' : 'Unlock'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
