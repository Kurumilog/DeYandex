# Yandex Market (`ru.yandex.market`)

Yandex Market uses background telemetry (like AppMetrica) to build heatmaps, track abandoned carts, and profile users based on viewed items. It may constantly hold partial wakelocks to sync catalog states and check for promotions.

## Recommended AppOps Restrictions

Apply the following commands to make Yandex Market a passive app that only runs when you actively use it.

### 1. Stop Background Execution and Wakelocks

Eliminates background parsers, analytics collection, and battery drain from partial wakelocks.

```sh
adb shell cmd appops set ru.yandex.market RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.market WAKE_LOCK ignore
```

### 2. Restrict Precise Location

The app does not need constant precise GPS tracking. You can manually enter addresses or use coarse location when choosing delivery points.

```sh
adb shell cmd appops set ru.yandex.market ACCESS_FINE_LOCATION ignore
```

## Russian Version

[yandex-market-ru.md](yandex-market-ru.md)
