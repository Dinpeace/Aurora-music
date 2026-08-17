The HomeScreen patch above is intentionally a placement patch.
Before applying it, change `songs: const []` to the Home screen's actual
`List<Song>` source if HomeScreen already exposes one.

The standalone widget is safe to add independently and reads the existing
ListeningHistoryService + TasteProfileService + ListeningInsightsService.
