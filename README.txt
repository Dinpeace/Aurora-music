Aurora Recommendation Complete Fix v6

Replace the two service files included here. This is a complete replacement,
not a patch, so it avoids patch-context mismatches.

The ranking rules intentionally preserve skipped/recent tracks in the result
while pushing them below fresh candidates.

Then run:
flutter analyze
flutter test

Do not commit until the full suite has zero failures.
