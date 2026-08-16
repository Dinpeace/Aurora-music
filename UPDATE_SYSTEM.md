# Aurora Music Update System

Aurora checks the latest public GitHub Release from `Dinpeace/Aurora-music` and compares its semantic version with the installed app version.

The update flow is intentionally non-destructive: it never installs an APK automatically. When a newer release is found, Aurora shows the release notes and directs the user to the official GitHub Releases page.
