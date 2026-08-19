Aurora Smart Queue v9

Time-aware preference decay built on v8.

Signals:
- recent taste is weighted more strongly
- historical taste decays gradually with age
- mature preferences retain a 20% floor
- recent skips remain decisive
- exploration remains available for unseen tracks
- excluded IDs remain respected
- v8 long-term preference learning remains the foundation

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
