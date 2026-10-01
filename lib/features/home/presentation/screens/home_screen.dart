import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/shared/widgets/ad_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // The header and the feature grid both scroll together. They used to be
      // a `Column` with the grid in an `Expanded`, which meant the grid — being
      // the only flexible child — absorbed the entire height deficit on a short
      // or narrow surface. At 600x1000 the wrapped header consumed the budget
      // and the grid collapsed to zero height: the a11y tree and the rendered
      // pixels were both completely empty, with no overflow error to hint at
      // it, so the screen's entire primary surface silently disappeared. A
      // sliver grid cannot collapse — the content simply scrolls instead.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to ${AppConstants.appName}',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1024 ? 3 : 2,
              // A square tile cannot hold a 32-48px icon, a two-line title and
              // a three-line description, so the two-column phone layout uses a
              // taller tile. Three columns on a wide window have ample width
              // and stay square.
              childAspectRatio: MediaQuery.of(context).size.width > 1024
                  ? 1.0
                  : 0.72,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _FeatureCard(
                  icon: Icons.password,
                  title: 'Password Generator',
                  description: 'Generate secure random passwords',
                  onTap: () => context.go('/password-generator'),
                ),
                _FeatureCard(
                  icon: Icons.chat,
                  title: 'Passphrase Generator',
                  description: 'Create memorable passphrases',
                  onTap: () => context.go('/passphrase-generator'),
                ),
                _FeatureCard(
                  icon: Icons.pin,
                  title: 'PIN Generator',
                  description: 'Generate secure PIN codes',
                  onTap: () => context.go('/pin-generator'),
                ),
                _FeatureCard(
                  icon: Icons.fingerprint,
                  title: 'UUID Generator',
                  description: 'Generate unique identifiers',
                  onTap: () => context.go('/uuid-generator'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The tile's height is dictated by the grid's aspect ratio, not by its
    // content, so the content has to be able to give way. A fixed 48px icon
    // plus two unbounded Text widgets overflowed on every phone width
    // (measured: 57-365px of vertical overflow at 240/280/320/360/412dp).
    // Sizing the icon to the available width and letting the text flex with an
    // ellipsis means the card degrades gracefully instead of overflowing.
    final compact = MediaQuery.of(context).size.width < 600;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 32 : 48, color: colorScheme.primary),
              SizedBox(height: compact ? 8 : 12),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
