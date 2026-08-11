from pathlib import Path

path = Path("lib/features/settings/settings_screen.dart")
if not path.exists():
    raise SystemExit("ERROR: Run this from ~/aurora_music.")

text = path.read_text(encoding="utf-8")
original = text

if "import 'dart:async';" not in text:
    text = text.replace("import 'dart:convert';", "import 'dart:async';\nimport 'dart:convert';", 1)

if "package:firebase_auth/firebase_auth.dart" not in text:
    text = text.replace(
        "import 'package:dio/dio.dart';",
        "import 'package:dio/dio.dart';\nimport 'package:firebase_auth/firebase_auth.dart';",
        1,
    )

if "import '../../core/auth/auth_service.dart';" not in text:
    text = text.replace(
        "import '../player/player_controller.dart';",
        "import '../../core/auth/auth_service.dart';\nimport '../player/player_controller.dart';",
        1,
    )

anchor = "  bool _checkingForUpdates = false;\n"
if "_currentUser" not in text:
    text = text.replace(
        anchor,
        anchor + "\n  User? _currentUser;\n  StreamSubscription<User?>? _authSubscription;\n",
        1,
    )

old_init = """  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
"""
new_init = """  @override
  void initState() {
    super.initState();
    _loadSettings();

    _currentUser = AuthService.instance.currentUser;
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
"""
if "_authSubscription = AuthService.instance.authStateChanges.listen" not in text:
    if old_init not in text:
        raise SystemExit("ERROR: initState block not found.")
    text = text.replace(old_init, new_init, 1)

text = text.replace(
    "onTap: () => _showComingSoon('Account & Google Sign-In'),",
    "onTap: _showAccountDialog,",
    1,
)

old_account = """                title: const Text(
                  'Aurora Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Optional • Sign in to sync your library',
                  style: TextStyle(color: Colors.white60),
                ),"""
new_account = """                title: Text(
                  _currentUser == null
                      ? 'Aurora Account'
                      : (_currentUser!.displayName ?? 'Aurora Account'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _currentUser == null
                      ? 'Optional • Sign in to sync your library'
                      : (_currentUser!.email ?? 'Signed in with Google'),
                  style: const TextStyle(color: Colors.white60),
                ),"""
if old_account in text:
    text = text.replace(old_account, new_account, 1)

if "Future<void> _showAccountDialog() async" not in text:
    marker = "  void _showUpdateMessage(String message) {"
    method = """  Future<void> _showAccountDialog() async {
    if (_currentUser == null) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF18181B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Color(0xFFA855F7),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aurora Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to sync your library across devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        try {
                          await AuthService.instance.signInWithGoogle();
                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.message ?? 'Google Sign-In failed.',
                              ),
                            ),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not sign in with Google.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can continue using Aurora without an account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final user = _currentUser!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage:
                      user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 34)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? 'Aurora User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                const ListTile(
                  leading: Icon(
                    Icons.cloud_done_outlined,
                    color: Color(0xFFA855F7),
                  ),
                  title: Text(
                    'Cloud Sync',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Ready to sync your Aurora library',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await AuthService.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

"""
    if marker not in text:
        raise SystemExit("ERROR: Account dialog insertion point not found.")
    text = text.replace(marker, method + marker, 1)

if text == original:
    raise SystemExit("ERROR: No changes were made.")

path.write_text(text, encoding="utf-8")
print("Patched lib/features/settings/settings_screen.dart")
