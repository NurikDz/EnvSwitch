#*If this code helped you, please drop a ⭐ to support the project**
# EnvSwitch

EnvSwitch is a minimalist **macOS menu bar app** for switching digital contexts fast—coding, gaming, relaxing, whatever you define. It uses a **“total user control”** approach: no bundled app lists; you create **environments** locally and choose which apps each one launches.

![Menu bar and environments](ss/screenshot-1.png)

![Settings and app gallery](ss/screenshot-2.png)

## Features

- **Context switching** — run groups of apps from the menu bar.
- **System vibes** — optional dark/light mode, wallpaper, and focus-style hiding of other apps per environment.
- **App gallery** — browse installed apps in settings.
- **Menu bar icon** — reflects the active environment.
- **SwiftUI** settings.

## Build with Xcode

**Requirements:** macOS **14+** and a recent **Xcode** (Swift 5).

1. Clone this repo and open **`EnvSwitch.xcodeproj`** in Xcode.
2. In the Project Navigator, select the **EnvSwitch** project, then the **EnvSwitch** app target.
3. Open the **Signing & Capabilities** tab and choose your **Team** so Xcode can sign the debug build.
4. Select the **EnvSwitch** scheme and a **My Mac** destination.
5. Press **⌘R** (**Product → Run**) to build and launch.

To produce a **DMG** locally (optional), see [**RELEASING.md**](RELEASING.md) and `scripts/package-dmg.sh`.

Pre-built **`EnvSwitch.dmg`** builds, when published, are attached on GitHub **Releases**.

## License

Copyright © 2026 NurikDz

EnvSwitch is free software: you may redistribute and/or modify it **only** under the terms of the [**GNU General Public License, version 3**](https://www.gnu.org/licenses/gpl-3.0.html), as published by the Free Software Foundation—**version 3 of the License, and not any later version** (“GPL-3.0-only”).

The complete legal terms are in the [`LICENSE`](LICENSE) file in this repository (the unmodified GPLv3 text from the Free Software Foundation). The SPDX license identifier for this project is **GPL-3.0-only**.
