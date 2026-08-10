# aurora_music

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Aurora-music

## Check for Updates

The Settings screen includes a manual update checker. Configure the update manifest URL with:

`--dart-define=AURORA_UPDATE_MANIFEST_URL=https://YOUR-DOMAIN/aurora/latest.json`

Expected JSON:

```json
{
  "version": "1.1.0",
  "url": "https://YOUR-DOMAIN/aurora",
  "changelog": "Bug fixes and improvements."
}
```

The feature is intentionally configurable so the update source can later be pointed at the Aurora Music GitHub Releases endpoint.

## Check for Updates

Aurora checks the latest published GitHub Release from:

`Dinpeace/Aurora-music`

The checker uses the public GitHub Releases API. The repository needs a published release with a version tag such as `v1.1.0` for Aurora to detect an update.
