import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/challenge_repository.dart';
import '../../data/models/challenge.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/guest_gate.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';

/// Challenges — admin-created goals (steps / distance) that reward wallet points.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(guestModeProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenges')),
        body: const GuestGate(
          icon: Icons.emoji_events_outlined,
          title: 'Challenges',
          message: 'Sign in to take on challenges and earn points for staying active.',
        ),
      );
    }

    final AsyncValue<List<Challenge>> async = ref.watch(challengesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(challengesProvider),
        child: async.when(
          loading: () => const SkeletonList(count: 4, itemHeight: 150),
          error: (Object e, _) => ListView(children: <Widget>[
            const SizedBox(height: 140),
            AsyncRetry(
              message: "Couldn't load challenges.",
              onRetry: () => ref.invalidate(challengesProvider),
            ),
          ]),
          data: (List<Challenge> list) {
            if (list.isEmpty) return const _EmptyChallenges();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: <Widget>[
                for (final Challenge c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ChallengeCard(c),
                  ),
              ].revealStagger(),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges();
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 24),
      children: <Widget>[
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: <Color>[
                FitBoxColors.red.withValues(alpha: 0.28),
                FitBoxColors.red.withValues(alpha: 0.06),
              ]),
              border: Border.all(color: FitBoxColors.red.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: FitBoxColors.red, size: 40),
          ),
        ),
        const SizedBox(height: 20),
        Text('No challenges right now',
            textAlign: TextAlign.center, style: AppText.kinetic(context, size: 22)),
        const SizedBox(height: 8),
        Text('Check back soon — new challenges to earn points are on the way.',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 14, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _ChallengeCard extends ConsumerStatefulWidget {
  const _ChallengeCard(this.c);
  final Challenge c;
  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  bool _busy = false;

  String _remaining(DateTime deadline) {
    final Duration d = deadline.difference(DateTime.now());
    if (d.isNegative) return 'Ended';
    if (d.inDays >= 1) return 'Ends in ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return 'Ends in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'Ends in ${d.inMinutes}m';
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      await ref.read(challengeRepositoryProvider).join(widget.c.id);
      ref.invalidate(challengesProvider);
    } catch (_) {
      _snack("Couldn't join the challenge.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      final int awarded =
          await ref.read(challengeRepositoryProvider).claim(widget.c.id);
      ref.invalidate(challengesProvider);
      ref.invalidate(walletProvider);
      _snack('🎉 Reward claimed — +$awarded points!');
    } catch (_) {
      _snack("Couldn't claim — the reward limit may be reached.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final Challenge c = widget.c;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(c.title,
                    style: AppTypography.title(size: 17, color: cs.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FitBoxColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+${c.rewardPoints} pts',
                    style: AppTypography.label(size: 11, color: FitBoxColors.red)),
              ),
            ],
          ),
          if (c.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(c.description,
                style: AppTypography.body(size: 13, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(c.isDistance ? Icons.route : Icons.directions_walk,
                  size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${c.goalLabel} · ${c.durationDays}d',
                  style: AppTypography.caption(size: 12, color: cs.onSurfaceVariant)),
              const Spacer(),
              if (c.userCap > 0)
                Text('First ${c.userCap} · ${c.rewardedSoFar} claimed',
                    style:
                        AppTypography.caption(size: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          if (c.joined) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.progressFraction,
                minHeight: 8,
                backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(FitBoxColors.red),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(c.progressLabel,
                    style: AppTypography.caption(size: 12, color: cs.onSurface)),
                const Spacer(),
                if (c.deadline != null && !c.claimed)
                  Text(_remaining(c.deadline!),
                      style: AppTypography.caption(
                          size: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _action(c),
        ],
      ),
    );
  }

  Widget _action(Challenge c) {
    if (c.claimed) {
      return _StatusPill(
          icon: Icons.check_circle_rounded,
          label: 'Reward claimed',
          color: FitBoxColors.credit);
    }
    if (c.canClaim) {
      return GlowButton(
        label: 'Claim +${c.rewardPoints} points',
        icon: Icons.redeem,
        loading: _busy,
        onPressed: _busy ? null : _claim,
      );
    }
    if (!c.joined) {
      return GlowButton(
        label: 'Join challenge',
        icon: Icons.add_task,
        loading: _busy,
        onPressed: _busy ? null : _join,
      );
    }
    if (c.capReached) {
      return const _StatusPill(
          icon: Icons.lock_outline,
          label: 'Reward limit reached',
          color: FitBoxColors.debit);
    }
    return const _StatusPill(
        icon: Icons.timelapse, label: 'In progress', color: FitBoxColors.red);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.button(size: 13, color: color)),
        ],
      ),
    );
  }
}
