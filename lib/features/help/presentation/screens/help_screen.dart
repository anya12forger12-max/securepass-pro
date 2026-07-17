import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Help', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Getting Started'),
                    subtitle: const Text('Learn the basics of SecurePass Pro'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Password Generator Guide'),
                    subtitle: const Text(
                      'How to create and manage passwords',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security Best Practices'),
                    subtitle: const Text('Tips for staying secure'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.keyboard),
                    title: const Text('Keyboard Shortcuts'),
                    subtitle: const Text('Speed up your workflow'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Report an Issue'),
                    subtitle: const Text('Let us know about problems'),
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
