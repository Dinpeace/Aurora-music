import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoplay = true;
  bool _gaplessPlayback = true;
  bool _showNotifications = true;
  bool _highQualityAudio = true;

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
                subtitle: const Text(
                  'Stop playback automatically',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Sleep timer'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Audio'),
          _settingsCard(
            children: [
              _switchTile(
                icon: Icons.high_quality_outlined,
                title: 'High quality audio',
                subtitle: 'Prefer higher quality when available',
                value: _highQualityAudio,
                onChanged: (value) {
                  setState(() => _highQualityAudio = value);
                },
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
                subtitle: const Text(
                  'Adjust your listening experience',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Equalizer'),
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
                subtitle: const Text(
                  'Blend songs into each other',
                  style: TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onTap: () => _showComingSoon('Crossfade'),
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
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white54),
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
