import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:securepass_pro/core/constants/spacing_constants.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: SpacingConstants.md),
          Expanded(
            child: _SearchBar(colorScheme: colorScheme),
          ),
          const SizedBox(width: SpacingConstants.sm),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, size: 20),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, size: 20),
            tooltip: 'Help',
          ),
          const SizedBox(width: SpacingConstants.sm),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: SpacingConstants.sm),
          Icon(
            Icons.search,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: SpacingConstants.xs),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {},
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Ctrl+K',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
