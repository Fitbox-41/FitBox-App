import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/map_identity_repository.dart';
import '../../data/territory_repository.dart';
import '../widgets/glass.dart';

/// Choose the name and tag shown on your territory.
///
/// The owner asked for players to be identifiable on the map by something they
/// choose, not by whatever name the shop account was opened with.
class MapIdentityScreen extends ConsumerStatefulWidget {
  const MapIdentityScreen({super.key});

  @override
  ConsumerState<MapIdentityScreen> createState() => _MapIdentityScreenState();
}

class _MapIdentityScreenState extends ConsumerState<MapIdentityScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _tag = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _tag.dispose();
    super.dispose();
  }

  Future<void> _save(MapIdentity current) async {
    setState(() => _saving = true);
    try {
      await ref.read(mapIdentityRepositoryProvider).save(
            displayName: _name.text.trim(),
            tag: _tag.text.trim(),
          );
      ref.invalidate(mapIdentityProvider);
      // The map caches the denormalised name, so make it refetch rather than
      // showing the old one until the next run.
      ref.invalidate(territoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved — this is how you appear on the map.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Surface the server's own wording when it rejects something, rather than a
  /// generic failure — it explains exactly which characters are allowed.
  String _messageFor(Object e) {
    if (e is DioException) {
      final Object? data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Could not save. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<MapIdentity> async = ref.watch(mapIdentityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map name & tag')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your profile.',
                style: AppTypography.body(size: 14, color: cs.onSurfaceVariant)),
          ),
        ),
        data: (MapIdentity id) {
          if (!_loaded) {
            _loaded = true;
            _name.text = id.displayName;
            _tag.text = id.tag;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              GlassCard(
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('How you appear on the map',
                        style: AppText.labelCaps(context)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      maxLength: 24,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Display name',
                        hintText: id.accountName.isEmpty ? 'Runner' : id.accountName,
                        helperText: 'Leave empty to use your account name.',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tag,
                      maxLength: 12,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tag (optional)',
                        hintText: 'e.g. JALANDHAR',
                        helperText: 'A short badge shown next to your name.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('PREVIEW', style: AppText.labelCaps(context)),
              const SizedBox(height: 8),
              GlassCard(
                radius: 18,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: FitBoxColors.red,
                      child: Text(
                        _initialOf(_name.text.trim().isEmpty
                            ? id.accountName
                            : _name.text.trim()),
                        style: AppText.kinetic(context, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _name.text.trim().isEmpty
                            ? id.effectiveName
                            : _name.text.trim(),
                        style: AppTypography.title(size: 16, color: cs.onSurface),
                      ),
                    ),
                    if (_tag.text.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FitBoxColors.red.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_tag.text.trim().toUpperCase(),
                            style: AppText.labelCaps(context,
                                size: 10, color: FitBoxColors.red)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlowButton(
                label: 'Save',
                loading: _saving,
                onPressed: _saving ? null : () => _save(id),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initialOf(String s) {
    final String t = s.trim();
    return t.isEmpty ? 'R' : t.substring(0, 1).toUpperCase();
  }
}
