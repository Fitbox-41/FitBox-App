import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/motion.dart';

/// Territory-capture map hub. The live map + capture logic arrive with the
/// Google Maps key; this is the full glass UI shell framing a stylised map with
/// a hero territory stat card, legend, and reset countdown.
class TerritoryScreen extends StatelessWidget {
  const TerritoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            const _Header(),
            const SizedBox(height: 16),
            const _MapFrame(),
            const SizedBox(height: 16),
            const _TerritoryStatCard(),
            const SizedBox(height: 16),
            const _DeployCard(),
          ].revealStagger(),
        ),
      ),
    );
  }
}

/// Screen title + reset-countdown pill.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text('Territory', style: AppText.kinetic(context, size: 30)),
        ),
        const _GlassPill(
          icon: Icons.timelapse,
          label: 'RESET 2D 14H',
          iconColor: FitBoxColors.red,
        ),
      ],
    );
  }
}

/// A small frosted pill (icon + caps label) used for status chips.
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: FitBoxColors.glassFill(b),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FitBoxColors.glassStroke(b)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: iconColor ?? FitBoxColors.red, size: 15),
          const SizedBox(width: 7),
          Text(label, style: AppText.labelCaps(context, size: 11)),
        ],
      ),
    );
  }
}

/// The map placeholder framed in a large rounded glass container, with an
/// overlaid legend and a "coming with GPS" note over the stylised map.
class _MapFrame extends StatelessWidget {
  const _MapFrame();

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(28);
    return SizedBox(
      height: 360,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const MapPlaceholder(showBadge: false),
              // Legend across the top of the map.
              const Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: <Widget>[
                    _LegendChip(color: FitBoxColors.red, label: 'YOURS'),
                    SizedBox(width: 8),
                    _LegendChip(color: FitBoxColors.debit, label: 'CONTESTED'),
                    SizedBox(width: 8),
                    _LegendChip(color: Colors.white54, label: 'OPEN'),
                  ],
                ),
              ),
              // "Map arrives with GPS" note pinned to the bottom of the frame.
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.satellite_alt,
                          color: FitBoxColors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live territory map arrives with GPS + maps',
                          style: AppTypography.caption(
                              size: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Hairline inner border to seat the map in the frame.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: br,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tinted-dot + caps-label chip for the map legend (over a dark map).
class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(label,
              style: AppText.labelCaps(context, size: 9, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Hero territory stat card — percentage captured (count-up), zones held, rank.
class _TerritoryStatCard extends StatelessWidget {
  const _TerritoryStatCard();

  static const double _percent = 62;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('TERRITORY CAPTURED', style: AppText.labelCaps(context)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FitBoxColors.red.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.circle, color: FitBoxColors.red, size: 8),
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
              CountUpText(
                value: _percent,
                builder: (BuildContext context, double v) => Text(
                  '${v.round()}%',
                  style: AppText.data(context, size: 56, color: FitBoxColors.red),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('of your area',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress track for the captured share.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              color: cs.onSurface.withValues(alpha: 0.1),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _percent / 100,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[FitBoxColors.red, FitBoxColors.redDark],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: cs.onSurface.withValues(alpha: 0.12)),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  label: 'ZONES HELD',
                  child: CountUpText(
                    value: 7,
                    builder: (BuildContext context, double v) => Text(
                      '${v.round()}',
                      style:
                          AppText.data(context, size: 26, color: cs.onSurface),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: cs.onSurface.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'YOUR RANK',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text('#4',
                          style: AppText.data(context,
                              size: 26, color: FitBoxColors.red)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Dominator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.kinetic(context, size: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A caps label stacked over a value, used inside the hero stat card.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.labelCaps(context, size: 10)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Call-to-action row prompting the user to run to claim more territory.
class _DeployCard extends StatelessWidget {
  const _DeployCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          Icon(Icons.directions_run, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Claim more territory by running',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 10),
          GlowButton(
            label: 'Deploy',
            icon: Icons.chevron_right,
            expand: false,
            height: 46,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Territory capture arrives with GPS + maps.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
