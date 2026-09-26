import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/domain/enums/notification_type.dart';
import 'package:securepass_pro/services/backup_service.dart';
import 'package:securepass_pro/services/clipboard_service.dart';
import 'package:securepass_pro/services/import_service.dart';
import 'package:securepass_pro/services/notification_service.dart';
import 'package:securepass_pro/services/vault_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openAppearance(BuildContext context) => context.go('/theme-studio');

  Future<void> _openSecurity(BuildContext context) async {
    final vault = VaultService();
    await showDialog<void>(
      context: context,
      builder: (context) => _SecurityDialog(vault: vault),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _NotificationsDialog(),
    );
  }

  Future<void> _openBackupAndRestore(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _BackupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Appearance'),
                    subtitle: const Text('Theme, colors, and display settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAppearance(context),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security'),
                    subtitle: const Text('Encryption, auto-lock, and privacy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openSecurity(context),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('In-app notification center'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openNotifications(context),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Export, import, and backup data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openBackupAndRestore(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityDialog extends StatefulWidget {
  const _SecurityDialog({required this.vault});

  final VaultService vault;

  @override
  State<_SecurityDialog> createState() => _SecurityDialogState();
}

class _SecurityDialogState extends State<_SecurityDialog> {
  static const List<({int minutes, String label})> _autoLockOptions = [
    (minutes: 1, label: '1 minute'),
    (minutes: 5, label: '5 minutes'),
    (minutes: 15, label: '15 minutes'),
    (minutes: 30, label: '30 minutes'),
    (minutes: 60, label: '60 minutes'),
  ];

  late final VaultService vault = widget.vault;
  final _pinController = TextEditingController();
  late int selected = _nearestAutoLockMinutes(vault.autoLockSeconds);
  String? _pinError;
  bool _settingPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final wasNew = _isNew;
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _pinError = 'PIN must be at least 4 characters');
      return;
    }
    setState(() {
      _settingPin = true;
      _pinError = null;
    });
    await vault.setVaultPin(pin);
    vault.setAutoLockSeconds(selected * 60);
    if (!mounted) return;
    _pinController.clear();
    setState(() => _settingPin = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasNew ? 'Vault PIN set' : 'Vault PIN updated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _isNew => !vault.hasPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLabel = _labelFor(selected);
    final pinEnabled = vault.hasPin;

    return AlertDialog(
      title: const Text('Security'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your vault is encrypted on-device with strong cryptography.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pin protect your vault; auto-lock re-locks it when you step away.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text('Vault PIN', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: _isNew ? 'Create vault PIN' : 'Enter new vault PIN',
                prefixIcon: const Icon(Icons.pin_outlined),
                border: const OutlineInputBorder(),
                errorText: _pinError,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _settingPin ? null : _setPin,
                icon: _settingPin
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isNew ? Icons.pin : Icons.refresh),
                label: Text(_isNew ? 'Set vault PIN' : 'Update PIN'),
              ),
            ),
            if (pinEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Vault protection enabled.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Auto-lock after', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedLabel,
              decoration: const InputDecoration(
                labelText: 'Inactivity timeout',
              ),
              items: [
                for (final option in _autoLockOptions)
                  DropdownMenuItem(
                    value: option.label,
                    child: Text(option.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => selected = _minutesFor(value));
              },
            ),
            if (!pinEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Set a vault PIN above to enable locking.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: pinEnabled
                  ? () {
                      vault.setAutoLockSeconds(selected * 60);
                      vault.lock();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Auto-lock updated and vault locked'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.lock),
              label: const Text('Apply & lock vault now'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  static String _labelFor(int minutes) {
    for (final option in _autoLockOptions) {
      if (option.minutes == minutes) return option.label;
    }
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }

  static int _nearestAutoLockMinutes(int autoLockSeconds) {
    final minutes = autoLockSeconds ~/ 60;
    var nearest = _autoLockOptions.first.minutes;
    var nearestDelta = (minutes - nearest).abs();
    for (final option in _autoLockOptions) {
      final delta = (minutes - option.minutes).abs();
      if (delta < nearestDelta) {
        nearest = option.minutes;
        nearestDelta = delta;
      }
    }
    return nearest;
  }

  static int _minutesFor(String label) {
    for (final option in _autoLockOptions) {
      if (option.label == label) return option.minutes;
    }
    return 5;
  }
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = NotificationService.instance;
    final notifications = service.getNotifications();

    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: double.maxFinite,
        child: notifications.isEmpty
            ? Text(
                'No notifications yet. Security, backup, and system '
                'events will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(_iconFor(item.type)),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                  );
                },
              ),
      ),
      actions: [
        if (notifications.isNotEmpty) ...[
          TextButton(
            onPressed: () {
              service.markAllAsRead();
              Navigator.of(context).pop();
            },
            child: const Text('Mark all read'),
          ),
          TextButton(
            onPressed: () {
              service.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Clear all'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}

class _BackupDialog extends StatefulWidget {
  const _BackupDialog();

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  final _restoreController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final backup = await BackupService.instance.createBackup();
      final exported = await BackupService.instance.exportBackup(backup.id);
      if (exported == null) throw StateError('Backup export produced no data');
      final json = jsonEncode(exported);
      await EnhancedClipboardService.instance.copy(json);
      if (!mounted) return;
      _show(
        'Encrypted backup copied to clipboard. It clears shortly, and it can '
        'only be restored on this device.',
      );
    } catch (e) {
      if (!mounted) return;
      _show('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      _show('Paste a backup first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ImportService.instance.importFromJson(trimmed);
      if (!mounted) return;
      if (result.success) {
        _show(
          'Restored ${result.successfulItems} of ${result.totalItems} items.',
        );
        _restoreController.clear();
      } else {
        _show('Restore failed: ${result.errorMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      _show('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Backup & Restore'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create an encrypted snapshot of your vault and copy it to the '
              'clipboard, or paste a backup below to restore.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Backups are tied to this device: the encryption key is not part '
              'of the backup file, so a backup can only be restored here — not '
              'on a new phone. Uninstalling the app deletes the vault and that '
              'key.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _createBackup,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy_all),
              label: const Text('Create encrypted backup'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _restoreController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Paste backup JSON',
                hintText: '{"v":1,"enc":true,...}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _restore(_restoreController.text),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from backup'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}