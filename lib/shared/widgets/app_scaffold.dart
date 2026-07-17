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
      if (currentRoute.startsWith('/${section.name}')) {
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
                context.go('/${section.name}');
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
        selectedIndex: _getMobileIndex(currentSection),
        onDestinationSelected: (index) {
          const sections = _mobileSections;
          context.go('/${sections[index].name}');
        },
        destinations: _mobileSections
            .map(
              (s) => NavigationDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.activeIcon),
                label: s.label,
              ),
            )
            .toList(),
      ),
    );
  }

  static const _mobileSections = <NavigationSection>[
    NavigationSection.home,
    NavigationSection.passwordGenerator,
    NavigationSection.settings,
    NavigationSection.about,
  ];

  int _getMobileIndex(NavigationSection? section) {
    if (section == null) return 0;
    final idx = _mobileSections.indexOf(section);
    return idx >= 0 ? idx : 0;
  }
}
