# Yandex Translate (`ru.yandex.translate`)

Despite having offline dictionaries, Yandex Translate constantly contacts servers in the background to send telemetry and check for dictionary updates.

## Recommended AppOps Restrictions

### 1. Stop Background Telemetry

Restrict network and analytics activity when the app is minimized. The translator should only function when you have it actively open on your screen.

```sh
adb shell cmd appops set ru.yandex.translate RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.translate WAKE_LOCK ignore
```

### 2. Protect Clipboard and System

**Crucial Security Measure:** Prevents the app from automatically scanning your clipboard. This also blocks Bluetooth scanning and system overlays.

```sh
# Clipboard
adb shell cmd appops set ru.yandex.translate READ_CLIPBOARD ignore

# System and Bluetooth
adb shell cmd appops set ru.yandex.translate SYSTEM_ALERT_WINDOW ignore
adb shell cmd appops set ru.yandex.translate BLUETOOTH_SCAN ignore
```

### 3. Resource Restriction

Moves the app to the `restricted` standby bucket.

```sh
adb shell am set-standby-bucket ru.yandex.translate restricted
```

## Russian Version

[yandex-translate-ru.md](yandex-translate-ru.md)
