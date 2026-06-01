# DeYandex

DeYandex is a practical Android privacy-hardening repository for popular
Yandex apps. The goal is not to "break" apps, but to remove permissions,
background activity, advertising identifiers, and telemetry paths that are not
needed for the core user-facing function of the app.

The project is focused on Android 14-16, ADB shell, no root, and no Shizuku.
That means every command should be reproducible by a normal user with USB
debugging enabled. The tradeoff is important: some permissions are install-time
or system-level and cannot be fully removed without stronger privileges.

## Current Guides

| App              | Package                | Status                |
| ---------------- | ---------------------- | --------------------- |
| Yandex Maps      | `ru.yandex.yandexmaps` | Draft guide available |
| Yandex Eats      | `ru.foodfox.client`    | Draft guide available |
| Yandex Go / Taxi | `ru.yandex.taxi`       | Draft guide available |

Read the current guides here:

- [docs/yandex-maps.md](docs/yandex-maps.md)
- [docs/yandex-maps-ru.md](docs/yandex-maps-ru.md) (Russian)
- [docs/yandex-eats.md](docs/yandex-eats.md)
- [docs/yandex-eats-ru.md](docs/yandex-eats-ru.md) (Russian)
- [docs/yandex-go.md](docs/yandex-go.md)
- [docs/yandex-go-ru.md](docs/yandex-go-ru.md) (Russian)

Future guides should follow the same structure: inspect requested permissions,
separate runtime permissions from install-time permissions, apply ADB-only
hardening, verify the result, and document what remains impossible without
root/Shizuku.

## Scope

This repository covers:

- revoking dangerous runtime permissions with `pm revoke`;
- restricting AppOps that control background execution, identifiers, alarms,
  clipboard access, notifications, and similar behavior;
- forcing apps into a restricted standby bucket;
- blocking background network access for a specific app UID;
- disabling the Google AdServices/Advertising ID stack globally;
- documenting Android-version differences found during real-device testing.

This repository does not claim that ADB-only hardening can remove every
tracking path. Foreground network traffic, bundled SDK behavior, install-time
permissions, app account sync, and some component-level behavior can remain
outside the reach of plain ADB shell.

## Requirements

- Android 14, 15, or 16 device.
- ADB installed on the computer.
- USB debugging enabled.
- Device visible in `adb devices`.

## Safety Notes

Use the commands app by app. Check the package name and UID before applying a
network policy. Some restrictions can affect convenience features such as
notifications, account login, QR scanning, calls from the app, background route
alerts, Android Auto integration, and location-based navigation.

If an app update resets AppOps or standby state, re-run the relevant guide.

## License

MIT

- [docs/yandex-browser.md](docs/yandex-browser.md)
- [docs/yandex-browser-ru.md](docs/yandex-browser-ru.md) (Russian)
- [docs/yandex-market.md](docs/yandex-market.md)
- [docs/yandex-market-ru.md](docs/yandex-market-ru.md) (Russian)
- [docs/yandex-music.md](docs/yandex-music.md)
- [docs/yandex-music-ru.md](docs/yandex-music-ru.md) (Russian)
- [docs/yandex-mail.md](docs/yandex-mail.md)
- [docs/yandex-mail-ru.md](docs/yandex-mail-ru.md) (Russian)
- [docs/yandex-searchplugin.md](docs/yandex-searchplugin.md)
- [docs/yandex-searchplugin-ru.md](docs/yandex-searchplugin-ru.md) (Russian)
- [docs/yandex-translate.md](docs/yandex-translate.md)
- [docs/yandex-translate-ru.md](docs/yandex-translate-ru.md) (Russian)
- [docs/yandex-disk.md](docs/yandex-disk.md)
- [docs/yandex-lavka.md](docs/yandex-lavka.md)
- [docs/yandex-keyboard.md](docs/yandex-keyboard.md)
- [docs/yandex-iot-note.md](docs/yandex-iot-note.md)

## Automated Script

You can use the interactive Bash script to automatically detect connected devices, check for installed Yandex apps, and apply the recommended privacy hardenings.

```bash
cd scripts
./deyandex.sh
```

The script supports both English and Russian and will ask for your confirmation before applying the rules.
