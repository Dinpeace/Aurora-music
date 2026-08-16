# Aurora Music 🎧💜🩵

Aurora Music is a modern Flutter music player focused on a beautiful listening experience, intelligent discovery, powerful playback, and a clean Aurora visual identity.

## ✨ Highlights

- 🎵 Local music library
- 🔎 Search for songs, artists, and albums
- 💿 Artist and album experiences
- ❤️ Favorites and playlists
- 🎧 Background and lock-screen playback
- 🚗 Android Auto and external media controls
- 🎚️ Equalizer and audio effects
- 🌊 Playback visualization
- 🧠 Smart recommendations, Radio, Smart Queue, mood and taste intelligence
- 🎤 Lyrics experience
- 📥 Downloads and offline playback
- ☁️ Optional account/cloud synchronization
- 🌙 Personalized appearance and playback preferences

## 📱 Distribution

Aurora Music is distributed independently through:

- GitHub Releases
- The official Aurora Music website (coming soon)

Google Play is not part of the current distribution plan.

## 🚀 Installation

1. Open the latest GitHub Release.
2. Download the signed Aurora Music APK.
3. Verify the published SHA-256 checksum if desired.
4. Install the APK on a compatible Android device.
5. Android may ask you to allow installation from your browser/file manager; only enable this for a source you trust.

## 🔐 Verify a Release

Each production release should publish a SHA-256 checksum alongside the APK. On Linux, verify it with:

```bash
sha256sum AuroraMusic-*.apk
```

Compare the result with the checksum published in the GitHub Release.

## 🛠️ Development

Requirements:

- Flutter SDK compatible with the version declared in `pubspec.yaml`
- Android SDK/toolchain

Run:

```bash
flutter pub get
flutter test
flutter analyze
flutter run
```

Before a release, both automated tests and analyzer checks must pass.

## 📦 Release

Production distribution is handled through GitHub Releases. The repository contains release automation and documentation for building the signed APK, generating checksums, and preparing release notes.

Do not commit signing keys, passwords, Firebase secrets, or other credentials.

## 🐛 Bugs & 💡 Features

Please use GitHub Issues for reproducible bug reports and feature requests. Include your Aurora version, Android version/device, steps to reproduce, and relevant logs without exposing private information.

## 🔐 Security

Please do not publish sensitive security vulnerabilities in a public issue. Follow the repository security policy for responsible disclosure.

## 📄 License

See the repository's license files and project documentation for the applicable terms.

---

**Aurora Music — your music, your atmosphere.** 💜🩵🎧
