import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/challenge_repository.dart';
import '../../data/models/fitness_stats.dart';
import '../../data/providers.dart';
import '../../data/recorded_runs.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/external_link.dart';
import '../widgets/glass.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FitnessStats s = ref.watch(fitnessStatsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? name = ref.watch(authControllerProvider).user?.name;
    final String greeting =
        (name != null && name.isNotEmpty) ? name.split(' ').first : 'athlete';

    // Warm the challenges list while the user is looking at this screen. It's a
    // network round trip to a serverless backend, so fetching it only once
    // Challenges is tapped is what made that tab feel slow to open. The
    // provider caches, so opening the tab then finds the answer already there.
    ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Hi, $greeting', style: AppText.kinetic(context, size: 26)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications_none, color: cs.onSurface),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recordedRunsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
              _StepsRing(stats: s),
              const SizedBox(height: 18),
              GlowButton(
                label: 'Start a run',
                icon: Icons.play_arrow_rounded,
                onPressed: () => _startRun(context),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department,
                      value: '${s.caloriesKcal}',
                      animateTo: s.caloriesKcal.toDouble(),
                      animatedFormat: (double v) => '${v.round()}',
                      label: 'kcal',
                      color: FitBoxColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.route,
                      value: s.distanceKm.toStringAsFixed(1),
                      animateTo: s.distanceKm,
                      animatedFormat: (double v) => v.toStringAsFixed(1),
                      label: 'km',
                      color: FitBoxColors.credit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: '${s.activeMinutes}',
                      animateTo: s.activeMinutes.toDouble(),
                      animatedFormat: (double v) => '${v.round()}',
                      label: 'mins',
                      color: FitBoxColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _NavCard(
                icon: Icons.emoji_events_outlined,
                title: 'Challenges',
                subtitle: 'Earn points for hitting goals',
                route: '/challenges',
              ),
              const SizedBox(height: 12),
              // The shop is the point of the points — opened over the app so
              // the user never leaves FitBox to spend what they've earned.
              const _NavCard(
                icon: Icons.storefront_outlined,
                title: 'FitBox Shop',
                subtitle: 'Spend your points on gear',
                shop: true,
              ),
            ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          ),
        ),
    );
  }

  void _startRun(BuildContext context) => context.push('/record-run');
}

/// A full-width tappable card: icon chip, title, subtitle, chevron.
class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.shop = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  /// Opens the shop over the app instead of navigating inside it.
  final bool shop;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      onTap: () => shop
          ? openInAppBrowser(context, AppConfig.shopUrl)
          : context.push(route!),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: FitBoxColors.red.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: FitBoxColors.red, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: AppTypography.title(size: 16, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.body(
                        size: 12.5, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(shop ? Icons.open_in_new : Icons.chevron_right,
              size: shop ? 18 : 24,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _StepsRing extends StatelessWidget {
  const _StepsRing({required this.stats});

  final FitnessStats stats;

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern();
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CardLabel("Today's activity"),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  final int animatedSteps = (stats.steps * t).round();
                  final double animatedProgress = stats.stepProgress * t;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 176,
                        height: 176,
                        child: CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              FitBoxColors.red),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(fmt.format(animatedSteps),
                              style: AppText.data(context,
                                  size: 36, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text('/ ${fmt.format(stats.stepGoal)} steps',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(stats.stepProgress * 100).round()}%',
                style: AppText.data(context,
                    size: 15,
                    color: FitBoxColors.red,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

