# Yandex Browser (`com.yandex.browser`)

Yandex Browser is heavily integrated with the Yandex ecosystem and acts as a central hub for data collection, cross-app tracking, and telemetry. It often runs in the background to sync data, preload feeds (like Yandex Zen), and maintain constant connections.

If you cannot uninstall it entirely (e.g., via Universal Android Debloater `pm uninstall -k --user 0 com.yandex.browser`), you can severely restrict its background activity and access to sensitive sensors.

## Recommended AppOps Restrictions

Apply the following commands via ADB to restrict Yandex Browser's permissions without breaking core foreground browsing functionality.

### 1. Stop Background Execution and Wakelocks

These commands prevent the browser from running services in the background and keeping the device awake, significantly saving battery and reducing tracking. Additionally, the app is moved to the `restricted` standby bucket.

```sh
adb shell cmd appops set com.yandex.browser RUN_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser WAKE_LOCK ignore
adb shell am set-standby-bucket com.yandex.browser restricted
```

### 2. Isolate Sensors and Identity

If you don't use Yandex Browser for AR search or the "Alice" voice assistant, restrict these sensors. This also blocks access to your calendar and phone identifiers.

```sh
# Location, Camera, and Microphone
adb shell cmd appops set com.yandex.browser FINE_LOCATION ignore
adb shell cmd appops set com.yandex.browser CAMERA ignore
adb shell cmd appops set com.yandex.browser RECORD_AUDIO ignore

# Identity and Identifiers
adb shell cmd appops set com.yandex.browser READ_CALENDAR ignore
adb shell cmd appops set com.yandex.browser READ_PHONE_STATE ignore
```

### 3. Protect Files and Media

Blocks access to photos and files on the device to prevent them from being scanned by analytics modules.

```sh
adb shell cmd appops set com.yandex.browser READ_EXTERNAL_STORAGE ignore
adb shell cmd appops set com.yandex.browser WRITE_EXTERNAL_STORAGE ignore
adb shell cmd appops set com.yandex.browser ACCESS_MEDIA_LOCATION ignore
```

### 4. Protect Clipboard Data

Prevents the browser from silently reading your clipboard (which could contain passwords, 2FA codes, or sensitive links) while running in the background.

```sh
adb shell cmd appops set com.yandex.browser READ_CLIPBOARD ignore
```

## Russian Version

A Russian version of this guide is available at [yandex-browser-ru.md](yandex-browser-ru.md).
