import 'package:flutter/material.dart';

import '../../data/models/listening_history_entry.dart';
import '../../data/services/listening_history_service.dart';
import '../../data/services/listening_insights_service.dart';
import '../../data/services/taste_profile_service.dart';

class IntelligenceDashboardScreen extends StatefulWidget {
  const IntelligenceDashboardScreen({super.key});

  @override
  State<IntelligenceDashboardScreen> createState() =>
      _IntelligenceDashboardScreenState();
}

class _IntelligenceDashboardScreenState
    extends State<IntelligenceDashboardScreen> {
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

    final history = List<ListeningHistoryEntry>.unmodifiable(_history.entries);
    final profile = TasteProfileService().build(
      history: history,
      favoriteArtists: const [],
      favoriteIds: const [],
    );

    final data = _insights.summarize(
      history: history,
      profile: profile,
    );

    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Aurora Intelligence'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(_data),
    );
  }

  Widget _buildBody(ListeningInsights? data) {
    if (data == null || !data.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Keep listening and Aurora will build your listening profile here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _hero(data),
        const SizedBox(height: 20),
        _metrics(data),
        const SizedBox(height: 20),
        _section(
          title: 'Top Artists',
          child: _ranking(data.topArtists),
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Top Albums',
          child: _ranking(data.topAlbums),
        ),
        const SizedBox(height: 16),
        if (data.topGenres.isNotEmpty)
          _section(
            title: 'Your Genres',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.topGenres.map((genre) {
                return Chip(
                  label: Text(genre),
                  backgroundColor: const Color(0xFF27272A),
                  labelStyle: const TextStyle(color: Colors.white70),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  Widget _hero(ListeningInsights data) {
    final completion = (data.completionRate * 100).round();
    final skip = (data.skipRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF25113D),
            Color(0xFF111827),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFC084FC),
            size: 28,
          ),
          const SizedBox(height: 14),
          const Text(
            'Your taste is taking shape.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completion% completion • $skip% skip rate',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(ListeningInsights data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _MetricCard(
          icon: Icons.play_arrow_rounded,
          value: '${data.totalPlays}',
          label: 'Total plays',
        ),
        _MetricCard(
          icon: Icons.skip_next_rounded,
          value: '${data.totalSkips}',
          label: 'Skipped',
        ),
        _MetricCard(
          icon: Icons.schedule_rounded,
          value: _duration(data.listeningTime),
          label: 'Listening time',
        ),
        _MetricCard(
          icon: Icons.music_note_rounded,
          value: '${data.totalTracks}',
          label: 'Tracked tracks',
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _ranking(List<InsightItem> items) {
    if (items.isEmpty) {
      return const Text(
        'Not enough data yet.',
        style: TextStyle(color: Colors.white38),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white38),
                  ),
                ),
                Expanded(
                  child: Text(
                    _titleCase(items[i].name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '${items[i].plays}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _duration(Duration value) {
    if (value.inHours > 0) return '${value.inHours}h ${value.inMinutes.remainder(60)}m';
    if (value.inMinutes > 0) return '${value.inMinutes}m';
    return '${value.inSeconds}s';
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
