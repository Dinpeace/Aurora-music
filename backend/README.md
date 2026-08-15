# Aurora Music API deployment

This FastAPI service provides the public search API for Aurora. Deploy it to
Cloud Run so the Flutter application uses an HTTPS URL, not a computer on your
local network.

## Deploy to Cloud Run

Prerequisites: a Google Cloud project with billing enabled and the Google Cloud
CLI authenticated for that project.

```bash
gcloud run deploy aurora-music-api \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --min-instances 1 \
  --set-env-vars ALLOWED_ORIGINS=*
```

Cloud Run prints a service URL such as
`https://aurora-music-api-xxxxx.asia-south1.run.app`.

Run the Flutter app using that URL:

```bash
flutter run \
  --dart-define=AURORA_API_BASE_URL=https://aurora-music-api-xxxxx.asia-south1.run.app
```

`--min-instances 1` keeps one instance warm for lower first-search latency. It
incurs cost; omit it when scale-to-zero is preferred.

## Playback source

This service intentionally returns metadata only. Production audio playback
must use tracks you are authorized to distribute or a music provider with a
playback license. Add that provider's server-side credentials here; never embed
provider secrets in the Flutter app.
