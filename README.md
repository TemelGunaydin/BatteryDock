# BatteryDock

BatteryDock is a tiny macOS menu bar app for checking the battery percentages of connected Bluetooth devices without opening System Settings.

It is built for one job: click the menu bar icon, see the devices macOS exposes, and get back to work.

![BatteryDock popover](docs/screenshots/popover.png)

## Features

- Menu bar popover with connected Bluetooth device battery percentages
- Support for Apple input devices, AirPods-style split readings, and devices whose battery data is exposed by macOS
- Optional menu bar percentage display
- Global keyboard shortcut, default `Option+B`
- Low battery notifications
- Launch at login
- Refresh interval controls
- Multiple languages
- No account, no backend, no analytics, no tracking

![BatteryDock settings](docs/screenshots/settings.png)

## Install

Download the latest `.dmg` from the [Releases](https://github.com/TemelGunaydin/BatteryDock/releases) page, open it, then drag `BatteryDock.app` into `Applications`.

The current GitHub build is not Developer ID-signed or notarized yet. If macOS blocks the first launch, right-click `BatteryDock.app` and choose `Open`.

## Device Support

BatteryDock can only show battery data that macOS makes available locally. If macOS itself does not expose a percentage for a headset, speaker, or third-party Bluetooth device, BatteryDock cannot reliably invent it.

This is why some devices may appear by name but show no battery percentage. The app keeps those devices visible and clearly marks unavailable battery data.

## Privacy

BatteryDock runs entirely on your Mac.

- No servers
- No analytics SDKs
- No tracking
- No accounts
- No Bluetooth data leaves your device

## Build From Source

Requirements:

- macOS 14 or newer
- Xcode 26 or newer

Run locally:

```bash
./script/build_and_run.sh
```

Create a DMG:

```bash
./script/package_dmg.sh
```

For a Gatekeeper-friendly public build, sign with a Developer ID certificate and notarize:

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="your-notarytool-profile" \
./script/package_dmg.sh
```

## License

MIT
