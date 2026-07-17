import 'package:flutter/material.dart';
import 'package:securepass_pro/domain/enums/navigation_section.dart';
import 'package:securepass_pro/core/constants/spacing_constants.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({
    required this.currentSection,
    required this.onSectionSelected,
    super.key,
  });

  final NavigationSection currentSection;
  final ValueChanged<NavigationSection> onSectionSelected;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isExpanded = true;

  static const _destinations = [
    NavigationSection.home,
    NavigationSection.passwordGenerator,
    NavigationSection.passphraseGenerator,
    NavigationSection.pinGenerator,
    NavigationSection.uuidGenerator,
    NavigationSection.randomGenerator,
    NavigationSection.randomStrings,
    NavigationSection.workspace,
    NavigationSection.diagnostics,
    NavigationSection.settings,
    NavigationSection.themeStudio,
    NavigationSection.help,
    NavigationSection.about,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(colorScheme),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConstants.xs,
                vertical: SpacingConstants.sm,
              ),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final section = _destinations[index];
                final isSelected = section == widget.currentSection;
                return _SidebarItem(
                  section: section,
                  isSelected: isSelected,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onSectionSelected(section),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildCollapseButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: SpacingConstants.sm),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            color: colorScheme.primary,
            size: 28,
          ),
          if (_isExpanded) ...[
            const SizedBox(width: SpacingConstants.sm),
            Expanded(
              child: Text(
                'SecurePass',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapseButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: () => setState(() => _isExpanded = !_isExpanded),
      icon: Icon(
        _isExpanded ? Icons.chevron_left : Icons.chevron_right,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final NavigationSection section;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.xs,
        vertical: 2,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: isExpanded ? '' : section.label,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConstants.sm,
                vertical: SpacingConstants.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? section.activeIcon : section.icon,
                    size: 20,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: SpacingConstants.sm),
                    Expanded(
                      child: Text(
                        section.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
