Aurora Recommendation Feedback Loop v2

Adds a dedicated, stateless feedback translator for existing listening history.

Signals:
- plays
- completion position
- replays
- skips

Behavior:
- Positive listening behavior reinforces candidates.
- Replays provide diminishing reinforcement.
- Skips strongly reduce ranking feedback.
- Repeated low-value skips can suppress a track.
- Feedback is bounded so one track cannot dominate ranking forever.

Apply patches/adaptive_recommendation_feedback.patch after adding the service.
Then run flutter analyze and flutter test.
