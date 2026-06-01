# Yandex Translate (`ru.yandex.translate`)

Despite having offline dictionaries, Yandex Translate constantly contacts servers in the background to send telemetry and check for dictionary updates.

## Recommended AppOps Restrictions

### 1. Stop Background Telemetry

Restrict network and analytics activity when the app is minimized. The translator should only function when you have it actively open on your screen.

```sh
adb shell cmd appops set ru.yandex.translate RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.translate WAKE_LOCK ignore
```

### 2. Protect Clipboard Data

**Crucial Security Measure:** Prevents the app from automatically scanning your clipboard. You will have to manually paste text to translate it, but this prevents leaks of passwords or 2FA codes.

```sh
adb shell cmd appops set ru.yandex.translate READ_CLIPBOARD ignore
```

## Russian Version

[yandex-translate-ru.md](yandex-translate-ru.md)
