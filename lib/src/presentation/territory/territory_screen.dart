import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/map_placeholder.dart';

/// Territory-capture map. The live map + capture logic arrive with the Google
/// Maps key; this is the full glass UI shell over a stylised map.
class TerritoryScreen extends StatelessWidget {
  const TerritoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MapPlaceholder()),
          // Reset countdown chip.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.timelapse, color: FitBoxColors.red, size: 16),
                    const SizedBox(width: 8),
                    Text('RESET IN 2D 14H',
                        style: AppText.labelCaps(context,
                            size: 11, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          // Bottom status card.
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('YOUR AREA THIS WEEK',
                          style: AppText.labelCaps(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: FitBoxColors.red.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.circle,
                                color: FitBoxColors.red, size: 8),
                            const SizedBox(width: 6),
                            Text('ACTIVE ZONE',
                                style: AppText.labelCaps(context,
                                    size: 10, color: FitBoxColors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text('#4',
                          style: AppText.data(context,
                              size: 44,
                              italic: true,
                              color: FitBoxColors.red)),
                      const SizedBox(width: 10),
                      Text('Dominator',
                          style: AppText.kinetic(context, size: 30)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Icon(Icons.directions_run,
                          color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Claim more by running',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                      GlowButton(
                        label: 'Deploy',
                        icon: Icons.chevron_right,
                        expand: false,
                        height: 46,
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                              'Territory capture arrives with GPS + maps.'),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
