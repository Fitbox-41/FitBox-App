import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/map_placeholder.dart';

/// Live run recording. GPS tracking + the live map land with the Maps key; this
/// is the full glass UI (timer, metrics, controls) over the map placeholder.
class RecordRunScreen extends StatelessWidget {
  const RecordRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MapPlaceholder(showBadge: false)),
          // GPS status + close.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.circle,
                          color: FitBoxColors.credit, size: 10),
                      const SizedBox(width: 8),
                      Text('GPS READY',
                          style: AppText.labelCaps(context,
                              size: 11, color: Colors.white)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Bottom control sheet.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('TOTAL TIME', style: AppText.labelCaps(context)),
                    const SizedBox(height: 6),
                    Text('00:00',
                        style: AppText.data(context, size: 56, italic: true)),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        _metric(context, 'Distance', '0.0', 'km'),
                        _sep(cs),
                        _metric(context, 'Avg pace', "0'00", '/km'),
                        _sep(cs),
                        _metric(context, 'Calories', '0', 'kcal'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _circleBtn(context, Icons.pause, false, () {}),
                        _circleBtn(context, Icons.stop, true,
                            () => context.pop()),
                        _circleBtn(context, Icons.layers_outlined, false, () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep(ColorScheme cs) => Container(
      width: 1, height: 34, color: cs.onSurface.withValues(alpha: 0.12));

  Widget _metric(
      BuildContext context, String label, String value, String unit) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.labelCaps(context, size: 10)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(value,
                  style: AppText.data(context, size: 22, italic: true)),
              const SizedBox(width: 2),
              Text(unit,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
      BuildContext context, IconData icon, bool primary, VoidCallback onTap) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 76 : 60,
        height: primary ? 76 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? FitBoxColors.red : cs.onSurface.withValues(alpha: 0.08),
          border: primary
              ? null
              : Border.all(color: cs.onSurface.withValues(alpha: 0.18)),
          boxShadow: primary
              ? <BoxShadow>[
                  BoxShadow(
                    color: FitBoxColors.red.withValues(alpha: 0.5),
                    blurRadius: 22,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Icon(icon,
            color: primary ? Colors.white : cs.onSurface,
            size: primary ? 32 : 26),
      ),
    );
  }
}
