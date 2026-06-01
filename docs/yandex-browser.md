# Yandex Browser (`com.yandex.browser`)

Yandex Browser is heavily integrated with the Yandex ecosystem and acts as a central hub for data collection, cross-app tracking, and telemetry. It often runs in the background to sync data, preload feeds (like Yandex Zen), and maintain constant connections.

If you cannot uninstall it entirely (e.g., via Universal Android Debloater `pm uninstall -k --user 0 com.yandex.browser`), you can severely restrict its background activity and access to sensitive sensors.

## Recommended AppOps Restrictions

Apply the following commands via ADB to restrict Yandex Browser's permissions without breaking core foreground browsing functionality.

### 1. Stop Background Execution and Wakelocks

These commands prevent the browser from running services in the background and keeping the device awake, significantly saving battery and reducing tracking.

```sh
adb shell cmd appops set com.yandex.browser RUN_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser WAKE_LOCK ignore
```

### 2. Isolate Sensors (Location, Camera, Microphone)

If you don't use Yandex Browser for AR search, precise navigation, or the "Alice" voice assistant, restrict these sensors.

```sh
adb shell cmd appops set com.yandex.browser ACCESS_FINE_LOCATION ignore
adb shell cmd appops set com.yandex.browser CAMERA ignore
adb shell cmd appops set com.yandex.browser RECORD_AUDIO ignore
```

### 3. Protect Clipboard Data

Prevents the browser from silently reading your clipboard (which could contain passwords, 2FA codes, or sensitive links) while running in the background.

```sh
adb shell cmd appops set com.yandex.browser READ_CLIPBOARD ignore
```

## Russian Version

A Russian version of this guide is available at [yandex-browser-ru.md](yandex-browser-ru.md).
