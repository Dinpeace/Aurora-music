Aurora Smart Queue v20-v40 Drop-In Layer

IMPORTANT:
- Additive to v1-v19.
- Does not replace SmartQueueService.
- No pubspec changes.
- No third-party packages.
- No changes to existing v1-v19 files are required.

Files:
lib/data/services/aurora_smart_queue_v20_v40.dart
test/data/services/aurora_smart_queue_v20_v40_test.dart

Milestones:
v20 conflict resolution
v21 session state
v22 momentum
v23 skip prediction
v24 transitions
v25 diversity
v26 dynamic queue length
v27 next-track prediction
v28 context
v29 automatic modes
v30 taste layers
v31 taste decay
v32 preference recovery
v33 recommendation result/facade
v34 explanation primitives
v35/v36 presentation primitives
v37 feedback
v38 embeddings
v39 semantic discovery
v40 personal DJ facade

Install:
1. Extract this archive into the Aurora project.
2. Run:
   flutter analyze
   flutter test

Do not delete or overwrite existing v1-v19 services.

Fix included: v20-v40 confidence math is explicitly converted to double for Dart's num-returning math.max.
