import 'package:flutter/material.dart';

import '../../../data/models/song.dart';
import '../../../data/services/listening_history_service.dart';
import '../../../data/services/listening_insights_service.dart';
import '../../../data/services/taste_profile_service.dart';

class ListeningInsightsSection extends StatefulWidget {
  const ListeningInsightsSection({
    super.key,
    required this.songs,
  });

  final List<Song> songs;

  @override
  State<ListeningInsightsSection> createState() =>
      _ListeningInsightsSectionState();
}

class _ListeningInsightsSectionState extends State<ListeningInsightsSection> {
  final ListeningHistoryService _history = ListeningHistoryService();
  final ListeningInsightsService _insights = ListeningInsightsService();

  ListeningInsights? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _history.initialize();

    final songs = widget.songs;
    final favorites = songs.where((song) => song.favorite).toList();

    final profile = TasteProfileService().build(
      history: _history.entries,
      favoriteArtists:
          favorites.map((song) => song.artist).toList(),
      favoriteIds:
          favorites.map((song) => song.id).toList(),
    );

    final result = _insights.summarize(
      history: _history.entries,
      profile: profile,
    );

    if (!mounted) return;

    setState(() {
      _data = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _data;
    if (data == null || !data.hasData) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF18181B),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Listening',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.topArtists.isEmpty
                ? 'Aurora is learning your taste.'
                : 'You have been listening mostly to ${_displayName(data.topArtists.first.name)}.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                value: '${data.totalPlays}',
                label: 'Plays',
                icon: Icons.play_arrow_rounded,
              ),
              _Metric(
                value: '${(data.completionRate * 100).round()}%',
                label: 'Completion',
                icon: Icons.check_circle_outline,
              ),
              _Metric(
                value: '${(data.skipRate * 100).round()}%',
                label: 'Skip rate',
                icon: Icons.skip_next_rounded,
              ),
              _Metric(
                value: _formatDuration(data.listeningTime),
                label: 'Listening',
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          if (data.topGenres.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.topGenres.take(3).map((genre) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF27272A),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  String _displayName(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 19),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
