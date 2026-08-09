# Aurora Music — Local Online Provider Test

The Flutter app can connect to the local Flask provider through `AURORA_API_BASE_URL`.

## 1. Start the provider

From the project root, with the Python virtual environment active:

```bash
python server/app.py
```

## 2. Run Aurora on Linux desktop

```bash
flutter run -d linux --dart-define=AURORA_API_BASE_URL=http://127.0.0.1:8765
```

## 3. Run Aurora on an Android device on the same Wi-Fi

Use the computer's LAN address shown by Flask (for example `10.83.87.45`):

```bash
flutter run --dart-define=AURORA_API_BASE_URL=http://10.83.87.45:8765
```

The debug Android manifest permits the local HTTP connection for development only.

## 4. Test

Open Search and search for a song. The results should come from the local provider.

This step tests **metadata/search connectivity only**. The provider currently returns an empty `streamUrl`, so online audio playback is not expected to work yet.
