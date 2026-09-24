import 'package:flutter/material.dart';
import 'package:securepass_pro/domain/entities/vault_entry.dart';
import 'package:securepass_pro/domain/enums/vault_entry_type.dart';
import 'package:securepass_pro/services/clipboard_service.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';
import 'package:uuid/uuid.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  final VaultService _vault = VaultService();
  final Set<String> _revealed = {};
  List<VaultEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vault.lockIfAutoLockElapsed();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasLocked = _vault.isLocked;
      _vault.lockIfAutoLockElapsed();
      if (wasLocked != _vault.isLocked && mounted) {
        setState(() {});
      }
    }
  }

  void _load() {
    setState(() {
      _entries = _vault.getEntries();
    });
  }

  Future<void> _addEntry() async {
    final created = await showDialog<VaultEntry>(
      context: context,
      builder: (context) => const _AddEntryDialog(),
    );
    if (created == null) return;
    _vault.addEntry(created);
    _load();
  }

  void _toggleReveal(VaultEntry entry) {
    setState(() {
      if (_revealed.contains(entry.id)) {
        _revealed.remove(entry.id);
      } else {
        _revealed.add(entry.id);
      }
    });
  }

  Future<void> _copyValue(VaultEntry entry) async {
    await EnhancedClipboardService.instance.copy(entry.value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${entry.type.label.toLowerCase()} and auto-clears shortly',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(VaultEntry entry) {
    _vault.updateEntry(entry.copyWith(isFavorite: !entry.isFavorite));
    _load();
  }

  Future<void> _deleteEntry(VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Remove "${entry.title}" from your vault? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _vault.removeEntry(entry.id);
    _load();
  }

  IconData _iconFor(VaultEntryType type) {
    switch (type) {
      case VaultEntryType.password:
        return Icons.lock_outline;
      case VaultEntryType.passphrase:
        return Icons.vpn_key_outlined;
      case VaultEntryType.pin:
        return Icons.pin_outlined;
      case VaultEntryType.recoveryCode:
        return Icons.restore_outlined;
      case VaultEntryType.apiToken:
        return Icons.key_outlined;
      case VaultEntryType.other:
        return Icons.sticky_note_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_vault.isLocked && _vault.hasPin) {
      return _LockedVaultView(onUnlocked: _load);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Workspace', style: theme.textTheme.headlineMedium),
              ),
              FilledButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add),
                label: const Text('Add entry'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_entries.length} ${_entries.length == 1 ? 'credential' : 'credentials'} in your secured vault',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _entries.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspaces,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your Workspace is empty',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Add entry" to save your first credential. '
                            'Everything is encrypted on-device.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final revealed = _revealed.contains(entry.id);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme
                                .colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            child: Icon(
                              _iconFor(entry.type),
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(entry.title),
                          subtitle: Text(
                            '${_favoriteNote(entry)} '
                            '${revealed ? entry.value : '••••••••••••'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: revealed ? 'Hide value' : 'Reveal value',
                                icon: Icon(
                                  revealed
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => _toggleReveal(entry),
                              ),
                              IconButton(
                                tooltip: 'Copy to clipboard',
                                icon: const Icon(Icons.content_copy),
                                onPressed: () => _copyValue(entry),
                              ),
                              IconButton(
                                tooltip: entry.isFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                icon: Icon(
                                  entry.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: entry.isFavorite
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                                onPressed: () => _toggleFavorite(entry),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteEntry(entry),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _favoriteNote(VaultEntry entry) {
    if (entry.isFavorite) {
      return '★ ${entry.type.label}:';
    }
    return '${entry.type.label}:';
  }
}

class _AddEntryDialog extends StatefulWidget {
  const _AddEntryDialog();

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _usernameController = TextEditingController();
  final _notesController = TextEditingController();
  VaultEntryType _type = VaultEntryType.password;

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _usernameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final entry = VaultEntry(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      type: _type,
      value: _valueController.text,
      workspaceId: WorkspaceService.instance.currentWorkspaceId ?? '',
      username: _usernameController.text.trim(),
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add credential'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VaultEntryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final type in VaultEntryType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. GitHub',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Title is required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Secret',
                  hintText: 'Password, passphrase, code, token…',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty)
                        ? 'Secret is required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username (optional)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LockedVaultView extends StatefulWidget {
  const _LockedVaultView({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_LockedVaultView> createState() => _LockedVaultViewState();
}

class _LockedVaultViewState extends State<_LockedVaultView> {
  final _pinController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await VaultService().unlock(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vault locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN to access your saved credentials.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('vault_pin_field'),
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: 'Vault PIN',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _error,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _unlock,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}