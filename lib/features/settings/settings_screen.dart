import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../player/player_controller.dart';

enum AudioQuality {
  low,
  normal,
  high,
  veryHigh,
}

extension AudioQualityLabel on AudioQuality {
  String get label {
    switch (this) {
      case AudioQuality.low:
        return 'Low';
      case AudioQuality.normal:
        return 'Normal';
      case AudioQuality.high:
        return 'High';
      case AudioQuality.veryHigh:
        return 'Very High';
    }
  }

  String get description {
    switch (this) {
      case AudioQuality.low:
        return 'Uses less data';
      case AudioQuality.normal:
        return 'Balanced quality and data use';
      case AudioQuality.high:
        return 'Higher quality when available';
      case AudioQuality.veryHigh:
        return 'Highest available quality';
    }
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _autoplayKey = 'settings.autoplay';
  static const _gaplessKey = 'settings.gapless';
  static const _notificationsKey = 'settings.notifications';
  static const _qualityKey = 'settings.audio_quality';
  static const _equalizerKey = 'settings.equalizer_levels';
  static const _crossfadeKey = 'settings.crossfade_seconds';

  static const _githubOwner = 'Dinpeace';
  static const _githubRepo = 'Aurora-music';
  static const _githubLatestReleaseApi =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  static const _githubReleasesPage =
      'https://github.com/$_githubOwner/$_githubRepo/releases';
  static const _currentVersion = '1.0.0';

  bool _autoplay = true;
  bool _gaplessPlayback = true;
  bool _showNotifications = true;
  AudioQuality _audioQuality = AudioQuality.high;
  List<double> _equalizerLevels = List<double>.filled(5, 0.0);
  Duration _crossfadeDuration = Duration.zero;
  bool _loading = true;
  bool _checkingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedCrossfade = Duration(
      seconds: (prefs.getInt(_crossfadeKey) ?? 0).clamp(0, 12).toInt(),
    );

    setState(() {
      _autoplay = prefs.getBool(_autoplayKey) ?? true;
      _gaplessPlayback = prefs.getBool(_gaplessKey) ?? true;
      _showNotifications = prefs.getBool(_notificationsKey) ?? true;
      _audioQuality = AudioQuality.values.firstWhere(
        (quality) => quality.name == prefs.getString(_qualityKey),
        orElse: () => AudioQuality.high,
      );
      _crossfadeDuration = savedCrossfade;
      final savedLevels = prefs.getStringList(_equalizerKey);
      if (savedLevels != null && savedLevels.length == 5) {
        _equalizerLevels = savedLevels
            .map((value) => double.tryParse(value) ?? 0.0)
            .map((value) => value.clamp(-12.0, 12.0).toDouble())
            .toList(growable: false);
      }
      _loading = false;
    });

    await ref
        .read(playerControllerProvider.notifier)
        .setCrossfadeDuration(savedCrossfade);
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setAudioQuality(AudioQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityKey, quality.name);

    if (!mounted) return;
    setState(() => _audioQuality = quality);
  }

  Future<void> _showAudioQualityPicker() async {
    final selected = await showModalBottomSheet<AudioQuality>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Audio quality',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Higher quality may use more data.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<AudioQuality>(
                  groupValue: _audioQuality,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.pop(context, value);
                    }
                  },
                  child: Column(
                    children: AudioQuality.values.map(
                      (quality) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Radio<AudioQuality>(
                            value: quality,
                            activeColor: const Color(0xFFA855F7),
                          ),
                          title: Text(
                            quality.label,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            quality.description,
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _setAudioQuality(selected);
    }
  }

  Future<void> _showSleepTimerPicker() async {
    final current = ref.read(playerControllerProvider).sleepTimerRemaining;

    final selected = await showModalBottomSheet<Duration?>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        final options = <Duration>[
          const Duration(minutes: 15),
          const Duration(minutes: 30),
          const Duration(minutes: 45),
          const Duration(minutes: 60),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sleep timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Playback will pause automatically.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                if (current > Duration.zero)
                  ListTile(
                    leading: const Icon(
                      Icons.timer_off_outlined,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Turn off timer',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.pop(context, Duration.zero),
                  ),
                ...options.map(
                  (duration) => ListTile(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: duration == current
                          ? const Color(0xFFA855F7)
                          : Colors.white70,
                    ),
                    title: Text(
                      '${duration.inMinutes} minutes',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: duration == current
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFA855F7),
                          )
                        : null,
                    onTap: () => Navigator.pop(context, duration),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await ref
          .read(playerControllerProvider.notifier)
          .setSleepTimer(selected);
    }
  }

  String _sleepTimerLabel(Duration remaining) {
    if (remaining <= Duration.zero) {
      return 'Stop playback automatically';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes > 0) {
      return seconds == 0
          ? 'Stops in $minutes min'
          : 'Stops in ${minutes}m ${seconds}s';
    }

    return 'Stops in ${seconds}s';
  }



  Future<void> _setCrossfadeDuration(Duration duration) async {
    final normalized = Duration(
      seconds: duration.inSeconds.clamp(0, 12).toInt(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_crossfadeKey, normalized.inSeconds);
    if (!mounted) return;
    setState(() => _crossfadeDuration = normalized);
    await ref
        .read(playerControllerProvider.notifier)
        .setCrossfadeDuration(normalized);
  }

  Future<void> _showCrossfadePicker() async {
    final options = <Duration>[
      Duration.zero,
      const Duration(seconds: 3),
      const Duration(seconds: 6),
      const Duration(seconds: 9),
      const Duration(seconds: 12),
    ];

    final selected = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Crossfade',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Blend the end of one song into the next.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (duration) => ListTile(
                    leading: Icon(
                      duration == Duration.zero
                          ? Icons.close_rounded
                          : Icons.tune_rounded,
                      color: duration == _crossfadeDuration
                          ? const Color(0xFFA855F7)
                          : Colors.white70,
                    ),
                    title: Text(
                      duration == Duration.zero
                          ? 'Off'
                          : '${duration.inSeconds} seconds',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: duration == _crossfadeDuration
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFA855F7),
                          )
                        : null,
                    onTap: () => Navigator.pop(context, duration),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _setCrossfadeDuration(selected);
    }
  }

  Future<void> _saveEqualizerLevels(List<double> levels) async {
    final normalized = levels
        .map((value) => value.clamp(-12.0, 12.0).toDouble())
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _equalizerKey,
      normalized.map((value) => value.toStringAsFixed(1)).toList(),
    );
    if (!mounted) return;
    setState(() => _equalizerLevels = normalized);
    await ref.read(playerControllerProvider.notifier).setEqualizerLevels(normalized);
  }

  Future<void> _showEqualizer() async {
    var levels = List<double>.from(_equalizerLevels);
    final result = await showModalBottomSheet<List<double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            const frequencies = ['60', '230', '910', '3.6k', '14k'];
            final presets = <String, List<double>>{
              'Flat': [0, 0, 0, 0, 0],
              'Bass Boost': [8, 5, 2, 0, 0],
              'Vocal': [-2, -1, 3, 5, 3],
              'Treble': [0, 0, 1, 5, 8],
            };
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 18),
                    const Align(alignment: Alignment.centerLeft, child: Text('Equalizer', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 4),
                    const Align(alignment: Alignment.centerLeft, child: Text('Adjust the 5-band equalizer.', style: TextStyle(color: Colors.white60))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(5, (index) => Expanded(child: Column(children: [
                          Text('${levels[index].round()} dB', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(min: -12, max: 12, divisions: 48, value: levels[index].clamp(-12.0, 12.0), activeColor: const Color(0xFFA855F7), inactiveColor: Colors.white12, onChanged: (value) => setSheetState(() => levels[index] = value)))),
                          Text(frequencies[index], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ]))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, runSpacing: 8, children: presets.entries.map((entry) => ActionChip(label: Text(entry.key), backgroundColor: const Color(0xFF27272A), labelStyle: const TextStyle(color: Colors.white), onPressed: () => setSheetState(() => levels = List<double>.from(entry.value)))).toList())),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => setSheetState(() => levels = [0, 0, 0, 0, 0]), child: const Text('Reset'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA855F7)), onPressed: () => Navigator.pop(context, levels), child: const Text('Apply'))),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) await _saveEqualizerLevels(result);
  }

  String _equalizerSummary() {
    if (_equalizerLevels.every((value) => value.abs() < 0.05)) return 'Flat';
    return '${_equalizerLevels.map((value) => value.round()).join(' / ')} dB';
  }

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdates) return;

    setState(() => _checkingForUpdates = true);

    try {
      final response = await Dio().get(
        _githubLatestReleaseApi,
        options: Options(
          responseType: ResponseType.json,
          headers: const {
            'Accept': 'application/vnd.github+json',
          },
          sendTimeout: Duration(seconds: 8),
          receiveTimeout: Duration(seconds: 8),
        ),
      );

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (data is! Map) {
        throw const FormatException('Invalid GitHub release response.');
      }

      final latestVersion = data['tag_name']?.toString().trim() ?? '';
      final releaseUrl = data['html_url']?.toString().trim() ??
          _githubReleasesPage;
      final changelog = data['body']?.toString().trim() ?? '';

      if (latestVersion.isEmpty) {
        throw const FormatException('GitHub release has no tag.');
      }

      final normalizedLatest = latestVersion.startsWith('v')
          ? latestVersion.substring(1)
          : latestVersion;

      final isNewer = _isVersionNewer(
        normalizedLatest,
        _currentVersion,
      );

      if (!mounted) return;

      if (!isNewer) {
        _showUpdateMessage(
          'You are up to date • v$_currentVersion',
        );
        return;
      }

      await _showUpdateDialog(
        latestVersion: normalizedLatest,
        updateUrl: releaseUrl,
        changelog: changelog,
      );
    } on DioException {
      if (mounted) {
        _showUpdateMessage(
          'Could not check for updates. Check your connection.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showUpdateMessage(
          'Could not read the GitHub release information.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingForUpdates = false);
      }
    }
  }

  bool _isVersionNewer(String latest, String current) {
    List<int> parse(String value) {
      final match = RegExp(r'^\d+(?:\.\d+){0,2}').firstMatch(value);
      final parts = (match?.group(0) ?? '0')
          .split('.')
          .map((part) => int.tryParse(part) ?? 0)
          .toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts.take(3).toList();
    }

    final latestParts = parse(latest);
    final currentParts = parse(current);

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] != currentParts[i]) {
        return latestParts[i] > currentParts[i];
      }
    }
    return false;
  }

  Future<void> _showUpdateDialog({
    required String latestVersion,
    required String updateUrl,
    required String changelog,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: const Text(
            'Update available',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aurora Music v$latestVersion is available.',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (changelog.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "What's new",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    changelog,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Later'),
            ),
            if (updateUrl.isNotEmpty)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showUpdateMessage(
                    'Open GitHub Releases to install v$latestVersion: $updateUrl',
                  );
                },
                child: const Text('Update'),
              ),
          ],
        );
      },
    );
  }

  void _showUpdateMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _sectionTitle('Account'),
          _settingsCard(
            children: [
              ListTile(
                leading: _iconBox(Icons.person_outline),
                title: const Text(
                  'Aurora Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Optional • Sign in to sync your library',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Account & Google Sign-In'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Playback'),
          _settingsCard(
            children: [
              _switchTile(
                icon: Icons.play_circle_outline_rounded,
                title: 'Autoplay',
                subtitle: 'Continue with the next song',
                value: _autoplay,
                onChanged: (value) {
                  setState(() => _autoplay = value);
                  _setBool(_autoplayKey, value);
                },
              ),
              _divider(),
              _switchTile(
                icon: Icons.all_inclusive_rounded,
                title: 'Gapless playback',
                subtitle: 'Reduce silence between tracks',
                value: _gaplessPlayback,
                onChanged: (value) {
                  setState(() => _gaplessPlayback = value);
                  _setBool(_gaplessKey, value);
                },
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.timer_outlined),
                title: const Text(
                  'Sleep timer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _sleepTimerLabel(
                    ref.watch(playerControllerProvider).sleepTimerRemaining,
                  ),
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: _showSleepTimerPicker,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Audio'),
          _settingsCard(
            children: [
              ListTile(
                leading: _iconBox(Icons.high_quality_outlined),
                title: const Text(
                  'Audio quality',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _audioQuality.label,
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: _showAudioQualityPicker,
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.equalizer_rounded),
                title: const Text(
                  'Equalizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _equalizerSummary(),
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: _showEqualizer,
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.tune_rounded),
                title: const Text(
                  'Crossfade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _crossfadeDuration == Duration.zero
                      ? 'Off'
                      : '${_crossfadeDuration.inSeconds} seconds',
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: _showCrossfadePicker,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Notifications'),
          _settingsCard(
            children: [
              _switchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Playback notifications',
                subtitle: 'Show player controls in notifications',
                value: _showNotifications,
                onChanged: (value) {
                  setState(() => _showNotifications = value);
                  _setBool(_notificationsKey, value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Library'),
          _settingsCard(
            children: [
              ListTile(
                leading: _iconBox(Icons.folder_open_rounded),
                title: const Text(
                  'Local music',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Manage music stored on this device',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Local music settings'),
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.cloud_outlined),
                title: const Text(
                  'Cloud sync',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Available with an optional account',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Cloud sync'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),
          _settingsCard(
            children: [
              ListTile(
                leading: _iconBox(Icons.system_update_outlined),
                title: const Text(
                  'Check for Updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _checkingForUpdates
                      ? 'Checking for the latest version...'
                      : 'Current version • v$_currentVersion',
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: _checkingForUpdates
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFA855F7),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                onTap: _checkingForUpdates ? null : _checkForUpdates,
              ),
              _divider(),
              ListTile(
                leading: _iconBox(Icons.info_outline_rounded),
                title: const Text(
                  'About Aurora Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Ad-free music experience',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: Text(
                  'v$_currentVersion',
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      value: value,
      activeThumbColor: const Color(0xFFA855F7),
      onChanged: onChanged,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: const Color(0xFFA855F7),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 20,
      color: Color(0xFF27272A),
    );
  }
}
