# Hardening Yandex Lavka (Яндекс Лавка)

While primarily a delivery app, Yandex Lavka requests permissions that can track your location and activities even when you aren't ordering anything.

## Risks Addressed
- **Background Location Tracking**: Prevents the app from waking up to check your location for "nearby stores".
- **Contact Access**: Stops the app from reading your address book (often used for "refer a friend" features).
- **Screen Recording (PROJECT_MEDIA)**: Blocks potential overlay or screen-capture telemetry.

## Hardening Steps

The interactive script (`deyandex.sh`) applies the following:

1. **Block Background Execution**
   ```bash
   adb shell cmd appops set com.yandex.lavka RUN_IN_BACKGROUND ignore
   adb shell cmd appops set com.yandex.lavka WAKE_LOCK ignore
   adb shell am set-standby-bucket com.yandex.lavka restricted
   ```
   *Impact*: You will not receive background push notifications about your delivery status. You must open the app to see updates.

2. **Isolate Sensitive Data**
   ```bash
   adb shell cmd appops set com.yandex.lavka FINE_LOCATION ignore
   adb shell cmd appops set com.yandex.lavka READ_CONTACTS ignore
   adb shell cmd appops set com.yandex.lavka PROJECT_MEDIA ignore
   ```
   *Impact*: You will need to manually enter your delivery address instead of relying on GPS auto-detect.