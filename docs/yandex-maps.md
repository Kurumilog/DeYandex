# DeYandex Guide: Yandex Maps

Package: `ru.yandex.yandexmaps`

Tested reference device:

- Device: Samsung SM-S901E
- Android: 16 / SDK 36
- Yandex Maps version: `28.6.5`
- Version code: `739172530`
- App UID on the tested device: `10368`

Your UID will be different. Always detect it locally before running network
policy commands.

## Introduction

Yandex Maps is not only a map renderer. The tested build includes account
integration, push messaging, advertising and attribution APIs, Android Auto
integration, foreground services, media/file providers, and analytics SDK
components. Some of that may support user-visible features, but a large part of
it is not necessary for opening a map, searching for places, or manually
building routes.

This guide documents what can be reduced with plain ADB and where the boundary
is. It is written for users who want a repeatable Android 14-16 procedure
without root, Magisk, Shizuku, or app repackaging.

## Goal

The goal is to keep Yandex Maps usable as a maps application while removing as
much non-essential access as possible without root or Shizuku.

Core map usage can reasonably need foreground network access and, if you want
turn-by-turn navigation or "my location", foreground location. Everything else
should be treated as optional until proven necessary: camera, microphone,
contacts, media, Bluetooth, activity recognition, background location,
advertising IDs, account access, background jobs, exact alarms, clipboard
reads, boot autostart, and background network traffic.

This guide is intentionally conservative. It avoids component disabling because
plain shell component control is restricted on modern Android builds and can
break the app more easily than permission and AppOps changes.

## What Yandex Maps Requests

The tested Yandex Maps build requests a broad set of permissions. They fall
into two practical groups.

### Install-Time Permissions Still Granted

These were `granted=true` on the tested Android 16 device. Most of them cannot
be revoked with `pm revoke` because Android grants them at install time or they
belong to SDK/system integrations.

| Permission                                                               | Why it matters                                                                               |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| `android.permission.INTERNET`                                            | Required for online maps, search, routing, SDK traffic, ads, telemetry.                      |
| `android.permission.ACCESS_NETWORK_STATE`                                | Lets the app inspect network state.                                                          |
| `android.permission.ACCESS_WIFI_STATE`                                   | Lets the app inspect Wi-Fi state.                                                            |
| `android.permission.CHANGE_WIFI_STATE`                                   | Can be restricted with AppOps on tested device.                                              |
| `android.permission.WAKE_LOCK`                                           | Lets background/foreground services keep CPU awake.                                          |
| `android.permission.RECEIVE_BOOT_COMPLETED`                              | Allows boot-time receivers; not blockable via `BOOT_COMPLETED` AppOps on tested Android 16.  |
| `android.permission.FOREGROUND_SERVICE`                                  | Enables foreground services.                                                                 |
| `android.permission.FOREGROUND_SERVICE_LOCATION`                         | Foreground location service type. Runtime location revoke still blocks real location access. |
| `android.permission.FOREGROUND_SERVICE_CAMERA`                           | Foreground camera service type. Runtime camera revoke still blocks real camera access.       |
| `android.permission.FOREGROUND_SERVICE_DATA_SYNC`                        | Data sync foreground service type.                                                           |
| `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`                   | Media playback foreground service type.                                                      |
| `android.permission.ACCESS_ADSERVICES_TOPICS`                            | Google Privacy Sandbox topics API.                                                           |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION`                       | Google attribution/measurement API.                                                          |
| `android.permission.ACCESS_ADSERVICES_AD_ID`                             | AdServices advertising ID access.                                                            |
| `com.google.android.gms.permission.AD_ID`                                | Google advertising ID access.                                                                |
| `com.google.android.gms.permission.ACTIVITY_RECOGNITION`                 | Google Play Services activity recognition integration.                                       |
| `com.google.android.c2dm.permission.RECEIVE`                             | Push messaging.                                                                              |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking.                                                                   |
| `android.permission.SCHEDULE_EXACT_ALARM`                                | Exact alarms; restrict with AppOps.                                                          |
| `android.permission.MANAGE_ACCOUNTS`                                     | Account integration.                                                                         |
| `android.permission.AUTHENTICATE_ACCOUNTS`                               | Account integration.                                                                         |
| `android.permission.USE_CREDENTIALS`                                     | Account credentials integration.                                                             |
| `com.yandex.permission.READ_CREDENTIALS`                                 | Yandex credential integration.                                                               |
| `android.permission.READ_SYNC_SETTINGS`                                  | Sync integration.                                                                            |
| `android.permission.WRITE_SYNC_SETTINGS`                                 | Sync integration.                                                                            |
| `android.permission.DETECT_SCREEN_CAPTURE`                               | System-level screen capture detection.                                                       |
| `android.permission.NFC`                                                 | NFC-related features.                                                                        |
| `android.permission.MODIFY_AUDIO_SETTINGS`                               | Audio/session behavior.                                                                      |
| `android.permission.VIBRATE`                                             | Haptics.                                                                                     |
| `android.permission.USE_BIOMETRIC`                                       | Biometric auth flows.                                                                        |
| `android.permission.USE_FINGERPRINT`                                     | Legacy biometric auth flows.                                                                 |
| `com.android.vending.BILLING`                                            | In-app billing.                                                                              |
| `com.android.alarm.permission.SET_ALARM`                                 | Alarm integration.                                                                           |
| `androidx.car.app.ACCESS_SURFACE`                                        | Android Auto / car integration.                                                              |
| `androidx.car.app.NAVIGATION_TEMPLATES`                                  | Android Auto navigation templates.                                                           |
| `com.android.launcher.permission.INSTALL_SHORTCUT`                       | Launcher shortcut creation.                                                                  |

### Runtime Permissions Revoked On Tested Device

These were `granted=false` after hardening. They are the main permissions that
plain ADB can revoke safely with `pm revoke`.

| Permission                                           | Impact if revoked                                           |
| ---------------------------------------------------- | ----------------------------------------------------------- |
| `android.permission.ACCESS_FINE_LOCATION`            | No precise current location. Manual map search still works. |
| `android.permission.ACCESS_COARSE_LOCATION`          | No approximate current location.                            |
| `android.permission.ACCESS_BACKGROUND_LOCATION`      | No background location.                                     |
| `android.permission.CAMERA`                          | No QR/photo camera features.                                |
| `android.permission.RECORD_AUDIO`                    | No voice input through app microphone permission.           |
| `android.permission.READ_CONTACTS`                   | No contact-based suggestions/import.                        |
| `android.permission.CALL_PHONE`                      | App cannot place calls directly.                            |
| `android.permission.POST_NOTIFICATIONS`              | No notifications; may affect navigation alerts.             |
| `android.permission.READ_MEDIA_IMAGES`               | No direct image library access.                             |
| `android.permission.READ_MEDIA_VIDEO`                | No direct video library access.                             |
| `android.permission.READ_MEDIA_VISUAL_USER_SELECTED` | No selected visual media access.                            |
| `android.permission.ACCESS_MEDIA_LOCATION`           | No photo/video location metadata access.                    |
| `android.permission.ACTIVITY_RECOGNITION`            | No motion/activity recognition.                             |
| `android.permission.BLUETOOTH_SCAN`                  | No Bluetooth scanning.                                      |
| `android.permission.BLUETOOTH_CONNECT`               | No Bluetooth device connection access.                      |
| `android.permission.BLUETOOTH_ADVERTISE`             | No Bluetooth advertising.                                   |
| `com.google.android.gms.permission.CAR_SPEED`        | No car speed permission.                                    |

### Observed Runtime Behavior

After hardening, the app still launched successfully on the tested Android 16
device. No fatal Yandex Maps crash was found in the checked logcat window.

The app did still start multiple processes/services while foreground:

- main process: `ru.yandex.yandexmaps`;
- account-related process: `ru.yandex.yandexmaps:passport`;
- analytics process/service: `ru.yandex.yandexmaps:AppMetrica` /
  `io.appmetrica.analytics.internal.AppMetricaService`.

Logcat also showed foreground DNS/network activity for Yandex endpoints while
the app was open. This is expected: Android's `restrict-background-blacklist`
does not block foreground traffic.

With location revoked, Yandex Maps logged handled `SecurityException` messages
when trying to start location providers. The app stayed running, but current
location/navigation features are naturally affected.

## Before You Start

Make sure ADB sees the device:

```bash
adb devices
```

Set variables in your shell. Replace the app UID after detecting it.

```bash
PACKAGE="ru.yandex.yandexmaps"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Example from the tested device:

```text
appId=10368
```

Use your own value. Do not name this shell variable `UID`: in bash/zsh that
name is usually readonly.

```bash
APP_UID=10368
```

## Step 1: Revoke Runtime Permissions

This removes dangerous permissions that are not required for basic manual map
usage. If you need live navigation with current location, do not revoke
`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`, or grant them only while
using the app through Android Settings.

```bash
adb shell pm revoke "$PACKAGE" android.permission.CAMERA
adb shell pm revoke "$PACKAGE" android.permission.RECORD_AUDIO
adb shell pm revoke "$PACKAGE" android.permission.READ_CONTACTS
adb shell pm revoke "$PACKAGE" android.permission.CALL_PHONE
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_BACKGROUND_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_MEDIA_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_IMAGES
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_VIDEO
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_VISUAL_USER_SELECTED
adb shell pm revoke "$PACKAGE" android.permission.ACTIVITY_RECOGNITION
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_SCAN
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_CONNECT
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_ADVERTISE
adb shell pm revoke "$PACKAGE" android.permission.POST_NOTIFICATIONS
```

Some Android versions may report that a permission is not changeable or was not
requested. That is acceptable; continue with the next command.

Verify:

```bash
adb shell dumpsys package "$PACKAGE" | grep "granted=false"
```

## Step 2: Disable Advertising ID And AdServices

These commands are global. They affect all apps on the device, not only Yandex
Maps. Use them only if that is acceptable.

```bash
adb shell settings put secure advertising_id "00000000-0000-0000-0000-000000000000"

adb shell device_config put adservices global_kill_switch true
adb shell device_config put adservices adid_kill_switch true
adb shell device_config put adservices measurement_kill_switch true
adb shell device_config put adservices adservice_enabled false
adb shell device_config put adservices adservice_system_service_enabled false

adb shell device_config set_sync_disabled_for_tests persistent
```

Verify:

```bash
adb shell settings get secure advertising_id
adb shell device_config get adservices global_kill_switch
adb shell device_config get adservices adid_kill_switch
adb shell device_config get adservices measurement_kill_switch
adb shell device_config get adservices adservice_enabled
adb shell device_config get adservices adservice_system_service_enabled
adb shell device_config get_sync_disabled_for_tests
```

Expected hardened values:

```text
00000000-0000-0000-0000-000000000000
true
true
true
false
false
persistent
```

## Step 3: Restrict AppOps

AppOps are useful for permissions and behaviors that are not cleanly removable
through `pm revoke`.

```bash
# Background execution
adb shell cmd appops set "$PACKAGE" RUN_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" RUN_ANY_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" START_FOREGROUND deny

# Scheduled work
adb shell cmd appops set "$PACKAGE" SCHEDULE_EXACT_ALARM deny

# Identifiers and account-style access
adb shell cmd appops set "$PACKAGE" GET_ACCOUNTS deny
adb shell cmd appops set "$PACKAGE" READ_DEVICE_IDENTIFIERS deny
adb shell cmd appops set "$PACKAGE" READ_PHONE_STATE deny

# Clipboard and Wi-Fi state changes
adb shell cmd appops set "$PACKAGE" READ_CLIPBOARD deny
adb shell cmd appops set "$PACKAGE" CHANGE_WIFI_STATE deny

# Notifications. Optional: can break navigation/status alerts.
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny
```

On Android 15/16, some runtime-linked operations are also represented at UID
level. Running the package-level command can return success while `appops get`
still prints an effective package-level `allow` line. Add the UID-level form:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" ACTIVITY_RECOGNITION deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
```

Boot autostart is version-dependent:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

On the tested Android 16 build this returns:

```text
Error: Unknown operation string: BOOT_COMPLETED
```

If you see that error, treat `RECEIVE_BOOT_COMPLETED` as not blockable through
plain ADB AppOps on your build.

Verify:

```bash
adb shell cmd appops get "$PACKAGE"
adb shell cmd appops get --uid "$PACKAGE"
```

Useful hardened lines include:

```text
RUN_IN_BACKGROUND: deny
RUN_ANY_IN_BACKGROUND: deny
START_FOREGROUND: deny
READ_CLIPBOARD: deny
CHANGE_WIFI_STATE: deny
READ_DEVICE_IDENTIFIERS: deny
SCHEDULE_EXACT_ALARM: deny
```

For runtime permissions that were revoked with `pm revoke`, Android may show a
mixed AppOps view such as UID mode `ignore` and package mode `allow`. In that
case, trust `dumpsys package` for the actual runtime grant state.

## Step 4: Restrict Standby Bucket

This pushes the app into Android's most restrictive normal standby bucket.
It limits background jobs and helps suppress WorkManager, datatransport, and
analytics scheduling while the app is not actively used.

```bash
adb shell am set-standby-bucket "$PACKAGE" restricted
```

Verify:

```bash
adb shell am get-standby-bucket "$PACKAGE"
```

Expected:

```text
45
```

Android can promote the app back after active use. Re-run this after app
updates or heavy usage sessions.

## Step 5: Block Background Network Access

This blocks network only when Yandex Maps is not in foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Verify:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Expected:

```text
Restrict background blacklisted UIDs: 10368
```

Use your own UID, not `10368`, unless your device reports the same value.

## All-In-One Script

Review the script before running it. It assumes you want maximum ADB-only
restriction, including no notifications and no app location permission.

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="ru.yandex.yandexmaps"
APP_UID="$(adb shell dumpsys package "$PACKAGE" | sed -n 's/.*appId=//p' | head -n 1 | tr -d '\r')"

if ! [[ "$APP_UID" =~ ^[0-9]+$ ]]; then
  echo "Error: Could not detect numeric APP_UID for $PACKAGE. Is the app installed?" >&2
  exit 1
fi

echo "[0/5] Package: $PACKAGE"
echo "[0/5] UID: $APP_UID"

echo "[1/5] Revoking runtime permissions"
RUNTIME_PERMS=(
  CAMERA
  RECORD_AUDIO
  READ_CONTACTS
  CALL_PHONE
  ACCESS_FINE_LOCATION
  ACCESS_COARSE_LOCATION
  ACCESS_BACKGROUND_LOCATION
  ACCESS_MEDIA_LOCATION
  READ_MEDIA_IMAGES
  READ_MEDIA_VIDEO
  READ_MEDIA_VISUAL_USER_SELECTED
  ACTIVITY_RECOGNITION
  BLUETOOTH_SCAN
  BLUETOOTH_CONNECT
  BLUETOOTH_ADVERTISE
  POST_NOTIFICATIONS
)

for perm in "${RUNTIME_PERMS[@]}"; do
  adb shell pm revoke "$PACKAGE" "android.permission.$perm" 2>/dev/null \
    && echo "  ok: $perm" \
    || echo "  skip: $perm"
done

echo "[2/5] Disabling AdServices globally"
adb shell settings put secure advertising_id "00000000-0000-0000-0000-000000000000"
adb shell device_config put adservices global_kill_switch true
adb shell device_config put adservices adid_kill_switch true
adb shell device_config put adservices measurement_kill_switch true
adb shell device_config put adservices adservice_enabled false
adb shell device_config put adservices adservice_system_service_enabled false
adb shell device_config set_sync_disabled_for_tests persistent

echo "[3/5] Restricting AppOps"
APPOPS=(
  RUN_IN_BACKGROUND
  RUN_ANY_IN_BACKGROUND
  START_FOREGROUND
  SCHEDULE_EXACT_ALARM
  GET_ACCOUNTS
  READ_DEVICE_IDENTIFIERS
  READ_PHONE_STATE
  READ_CLIPBOARD
  CHANGE_WIFI_STATE
  POST_NOTIFICATION
)

for op in "${APPOPS[@]}"; do
  adb shell cmd appops set "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op" \
    || echo "  skip: $op"
done

UID_APPOPS=(READ_PHONE_STATE ACTIVITY_RECOGNITION POST_NOTIFICATION)
for op in "${UID_APPOPS[@]}"; do
  adb shell cmd appops set --uid "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op (--uid)" \
    || echo "  skip: $op (--uid)"
done

adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore 2>/dev/null \
  && echo "  ok: BOOT_COMPLETED" \
  || echo "  skip: BOOT_COMPLETED unsupported on this build"

echo "[4/5] Setting standby bucket"
adb shell am set-standby-bucket "$PACKAGE" restricted

echo "[5/5] Blocking background network"
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"

echo
echo "Verification:"
adb shell am get-standby-bucket "$PACKAGE"
adb shell cmd netpolicy list restrict-background-blacklist
adb shell cmd appops get "$PACKAGE" | grep -E "RUN_IN_BACKGROUND|RUN_ANY_IN_BACKGROUND|START_FOREGROUND|READ_CLIPBOARD|CHANGE_WIFI_STATE|READ_DEVICE_IDENTIFIERS|SCHEDULE_EXACT_ALARM"
```

## Optional: Keep Foreground Location

If you want live navigation, you probably need foreground location. A practical
middle ground is:

- keep `ACCESS_BACKGROUND_LOCATION` revoked;
- allow approximate or precise location only while using the app in Android
  Settings;
- keep background execution, background network, exact alarms, identifiers,
  clipboard, and AdServices restricted.

Granting foreground location is a usability decision, not a requirement for
manual map browsing.

## What Remains Without Root Or Shizuku

Some things remain outside plain ADB control:

| Mechanism                              | Why it remains                                                                                                               |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Foreground network telemetry           | Background netpolicy does not apply while the app is open.                                                                   |
| AppMetrica service in foreground       | The tested app started `io.appmetrica.analytics.internal.AppMetricaService` while the app was foreground.                    |
| Install referrer permission            | Install-time Google Play permission.                                                                                         |
| Account permissions                    | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS`, and Yandex credential permissions are install-time.           |
| Boot permission on tested Android 16   | `BOOT_COMPLETED` AppOps operation was unavailable.                                                                           |
| `DETECT_SCREEN_CAPTURE`                | System-level permission.                                                                                                     |
| Foreground service types               | Install-time service type declarations; runtime permissions can neutralize camera/location access, but not the declarations. |
| Component-level SDK providers/services | Plain shell component disabling is restricted on modern Android and can break app startup.                                   |

For foreground telemetry control without root, the realistic next layer is a
local VPN firewall or DNS blocklist. That should be documented separately
because domain blocking can break maps, search, routing, login, payments, and
Android Auto in different ways.

## Reverting

Remove the background network restriction:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Reset standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Reset selected AppOps:

```bash
adb shell cmd appops reset "$PACKAGE"
```

Re-enable AdServices sync and values only if you intentionally disabled them
globally:

```bash
adb shell device_config set_sync_disabled_for_tests none
adb shell device_config put adservices global_kill_switch false
adb shell device_config put adservices adid_kill_switch false
adb shell device_config put adservices measurement_kill_switch false
adb shell device_config put adservices adservice_enabled true
adb shell device_config put adservices adservice_system_service_enabled true
```

Runtime permissions can be granted again from Android Settings. Prefer granting
only "while using the app" when possible.

## Conclusion

On Android 14-16 without root and without Shizuku, Yandex Maps can be hardened
meaningfully:

- dangerous runtime permissions can be revoked;
- AdServices and Advertising ID can be disabled globally;
- background execution and exact alarms can be restricted;
- background network can be blocked by UID;
- standby bucket can be forced to `restricted`.

This does not fully remove foreground telemetry. It does reduce passive data
collection when the app is closed or idle, and it limits access to sensors,
media, contacts, phone state, identifiers, clipboard, and background location.

### Addendum: Wakelock issue

Just like Navigator (`ru.yandex.yandexnavi`), Maps can hold wakelocks and query GPS long after closing. Apply `WAKE_LOCK ignore` to prevent this battery drain.
