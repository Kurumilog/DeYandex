# Yandex Maps (`ru.yandex.yandexmaps`)

Yandex Maps actively tracks user physical activity and phone status in the background.

## Recommended AppOps Restrictions

### 1. Block Activity Tracking

Prevents the app from knowing whether you are walking or using transport without your explicit knowledge.

```sh
adb shell cmd appops set ru.yandex.yandexmaps ACTIVITY_RECOGNITION ignore
adb shell cmd appops set ru.yandex.yandexmaps READ_PHONE_STATE ignore
```

### 2. Resource Restriction

Limits the app's background telemetry.

```sh
adb shell am set-standby-bucket ru.yandex.yandexmaps restricted
```
