import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/domain/enums/navigation_section.dart';
import 'package:securepass_pro/shared/widgets/app_sidebar.dart';
import 'package:securepass_pro/shared/widgets/app_top_bar.dart';
import 'package:securepass_pro/core/extensions/context_extensions.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = context.isDesktop;
    final currentRoute = GoRouterState.of(context).uri.toString();

    NavigationSection? currentSection;
    for (final section in NavigationSection.values) {
      if (currentRoute == '/${section.path}' ||
          currentRoute.startsWith('/${section.path}/')) {
        currentSection = section;
        break;
      }
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              currentSection: currentSection ?? NavigationSection.home,
              onSectionSelected: (section) {
                context.go('/${section.path}');
              },
            ),
            Expanded(
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(),
      body: child,
      bottomNavigationBar: NavigationBar(
        // The longest destination label is "Password Generator". The
        // NavigationBar renders labels as an unconstrained `Text` (no
        // maxLines), so on a narrow viewport the label wraps to three lines
        // and the fixed-height bar clips it mid-word ("Setting s",
        // "Worksp ace", "Passw ord Ge nerator"). Below the threshold the bar
        // switches to the Material compact form (icons only) and the label
        // stays reachable through the destination tooltip.
        labelBehavior: _isCompactNav(context)
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _getMobileIndex(currentSection),
        onDestinationSelected: (index) {
          const sections = _mobileSections;
          context.go('/${sections[index].path}');
        },
        destinations: _mobileSections
            .map(
              (s) => NavigationDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.activeIcon),
                label: s.label,
                tooltip: s.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Width of one navigation slot, in logical pixels.
  ///
  /// A destination label needs roughly 60dp of slot width to stay on two
  /// lines; below that it wraps to three and gets clipped. The label's text
  /// scaling is clamped to 1.3x by the NavigationBar itself, so the same
  /// clamp is applied here to keep the two in agreement.
  static bool _isCompactNav(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1.0).clamp(1.0, 1.3);
    final slotWidth = media.size.width / textScale / _mobileSections.length;
    return slotWidth < _kMinLabelSlotWidth;
  }

  static const double _kMinLabelSlotWidth = 60.0;

  static const _mobileSections = <NavigationSection>[
    NavigationSection.home,
    NavigationSection.passwordGenerator,
    NavigationSection.workspace,
    NavigationSection.settings,
    NavigationSection.about,
  ];

  int _getMobileIndex(NavigationSection? section) {
    if (section == null) return 0;
    final idx = _mobileSections.indexOf(section);
    return idx >= 0 ? idx : 0;
  }
}
