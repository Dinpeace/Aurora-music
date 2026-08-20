Aurora Music — YouTube Cloud Provider Bundle (Analyzer-Clean)

Purpose:
Add YouTube catalog/search support to Aurora's online-first architecture.

This bundle:
- uses the official YouTube Data API for metadata/search;
- keeps the API key server-side;
- exposes an Aurora API-facing Flutter service;
- does not extract, download, proxy, or expose raw YouTube audio;
- does not bypass YouTube playback restrictions;
- does not modify Smart Queue v1-v60.

Analyzer fix:
Backend tests use package imports instead of relative imports into lib/.
The backend package is named aurora_cloud_foundation and both backend test
files import from package:aurora_cloud_foundation/....

After extraction:
flutter analyze
flutter test

Expected result:
No issues found
All existing tests continue to pass.

Production note:
For 24/7 Aurora streaming, actual playback must use an authorized/appropriately
licensed playback source or an allowed YouTube playback surface. This bundle
handles catalog/search integration, not unrestricted YouTube audio extraction.
