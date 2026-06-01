# Yandex Mail (`ru.yandex.mail`)

While mail clients legitimately need background sync, Yandex Mail uses this persistent connection to gather profiling telemetry.

If you are okay with receiving new mail notifications _only_ when you manually open the app (Fetch/Pull instead of Push), you can apply strict restrictions.

## Recommended AppOps Restrictions

### 1. Stop Background Sync and Telemetry

This completely stops background metadata collection and TCP keep-alive pings.

```sh
adb shell cmd appops set ru.yandex.mail RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.mail WAKE_LOCK ignore
```

### 2. Protect Contacts Graph

Prevents unauthorized syncing of your device's address book under the guise of "improving recipient recommendations."

```sh
adb shell cmd appops set ru.yandex.mail READ_CONTACTS ignore
```

## Russian Version

[yandex-mail-ru.md](yandex-mail-ru.md)
