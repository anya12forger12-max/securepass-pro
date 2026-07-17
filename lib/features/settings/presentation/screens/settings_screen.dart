import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security'),
                    subtitle: const Text('Encryption, auto-lock, and privacy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Alert and notification preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Export, import, and backup data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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
