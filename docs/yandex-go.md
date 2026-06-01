# DeYandex Guide: Yandex Go / Taxi

Package: `ru.yandex.taxi`

The package was identified on the test device through the installed app list:

```text
package:.../ru.yandex.taxi-.../base.apk=ru.yandex.taxi installer=com.android.vending uid:10383
```

Launcher activity:

```text
ru.yandex.taxi/com.yandex.go.activity.alias.DefaultMainActivityAlias
```

Tested reference device:

- Device: Samsung SM-S901E
- Android: 16 / SDK 36
- Yandex Go version: `5.75.0`
- Version code: `50128094`
- Target SDK: `35`
- App UID on the tested device: `10383`

Your UID will be different. Always detect it locally before running network
policy commands.

## Introduction

Yandex Go / Taxi is more sensitive than a simple map app. It can handle rides,
addresses, location, account state, payment flows, calls, push notifications,
Yandex Passport, Yandex Pay, WebView, AppMetrica, map SDKs, and deep links.
Some of that is needed for ordering a real taxi ride, but not all of it needs
to work all the time or in the background.

This guide is written for Android 14-16, ADB shell, no root, no Shizuku, and no
APK repackaging. Runtime testing was no-login: the app was launched and
observed, but account login, real addresses, ride ordering, and payments were
not tested.

## Goal

The goal is to harden Yandex Go with plain ADB commands and document practical
exceptions for real ride usage.

Default strict privacy profile:

- no foreground/background location;
- no notifications;
- no camera, microphone, contacts, or phone state;
- no direct `CALL_PHONE`;
- no background network for the app UID;
- less background execution, exact alarms, clipboard access, and identifier access;
- globally disabled Advertising ID and Google AdServices.

For real ride ordering, this profile may be too strict. Practical exceptions
are documented below: foreground location, notifications, and direct calling
may be useful for ride status and coordination.

## What Yandex Go Requests

The tested `5.75.0` build requests a broad permission set. It is practical to
split these into install-time permissions and runtime permissions.

### Install-Time Permissions Still Granted

These were `granted=true` on the tested Android 16 device. Most cannot be
revoked with `pm revoke` because Android grants them at install time or they
belong to SDK/system integrations.

| Permission                                                               | Why it matters                                                                               |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| `android.permission.INTERNET`                                            | Rides, maps, address search, payments, SDK traffic, ads, telemetry.                          |
| `android.permission.ACCESS_NETWORK_STATE`                                | Lets the app inspect network state.                                                          |
| `android.permission.ACCESS_WIFI_STATE`                                   | Lets the app inspect Wi-Fi state.                                                            |
| `android.permission.CHANGE_WIFI_STATE`                                   | Can be restricted with AppOps.                                                               |
| `android.permission.WAKE_LOCK`                                           | Can keep CPU awake for tasks/services.                                                       |
| `android.permission.RECEIVE_BOOT_COMPLETED`                              | Boot receivers; `BOOT_COMPLETED` AppOps may be unavailable on Android 16 builds.             |
| `android.permission.FOREGROUND_SERVICE`                                  | Foreground services.                                                                         |
| `android.permission.FOREGROUND_SERVICE_LOCATION`                         | Foreground location service type. Runtime location revoke still blocks real location access. |
| `android.permission.FOREGROUND_SERVICE_DATA_SYNC`                        | Data sync foreground service type.                                                           |
| `android.permission.ACCESS_ADSERVICES_AD_ID`                             | AdServices advertising ID access.                                                            |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION`                       | Google attribution/measurement API.                                                          |
| `com.google.android.gms.permission.AD_ID`                                | Google Advertising ID access.                                                                |
| `com.google.android.c2dm.permission.RECEIVE`                             | Push messaging.                                                                              |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking.                                                                   |
| `android.permission.MANAGE_ACCOUNTS`                                     | Account / Passport integration.                                                              |
| `android.permission.AUTHENTICATE_ACCOUNTS`                               | Account / Passport integration.                                                              |
| `android.permission.USE_CREDENTIALS`                                     | Credential handling.                                                                         |
| `com.yandex.permission.READ_CREDENTIALS`                                 | Yandex credentials.                                                                          |
| `com.yandex.permission.AM_COMMUNICATION`                                 | Yandex account manager communication.                                                        |
| `android.permission.READ_SYNC_SETTINGS`                                  | Sync integration.                                                                            |
| `android.permission.WRITE_SYNC_SETTINGS`                                 | Sync integration.                                                                            |
| `android.permission.DETECT_SCREEN_CAPTURE`                               | Screen capture detection.                                                                    |
| `android.permission.DETECT_SCREEN_RECORDING`                             | Screen recording detection.                                                                  |
| `android.permission.NFC`                                                 | NFC/payment-adjacent flows.                                                                  |
| `android.permission.MODIFY_AUDIO_SETTINGS`                               | Audio/session behavior.                                                                      |
| `android.permission.VIBRATE`                                             | Haptics and alerts.                                                                          |
| `android.permission.USE_BIOMETRIC`                                       | Biometric auth/payment/account flows.                                                        |
| `android.permission.USE_FINGERPRINT`                                     | Legacy biometric flows.                                                                      |
| `android.permission.USE_FULL_SCREEN_INTENT`                              | Full-screen notification intent; AppOps was already `deny` on the tested device.             |
| `com.android.vending.BILLING`                                            | In-app billing.                                                                              |
| `ru.yandex.taxi.ORDER_NOTIFICATION`                                      | App-defined order notification permission.                                                   |
| `ru.yandex.taxi.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`                | App-defined dynamic receiver permission.                                                     |
| `com.yandex.yphone.permission.READ` / `WRITE`                            | Yandex phone integration.                                                                    |
| launcher badge permissions                                               | Badge counters for Samsung/Huawei/Oppo/HTC/Sony launchers.                                   |

### Runtime Permissions Revoked On Tested Device

These were `granted=false` on the tested device. They are the main permissions
plain ADB can revoke with `pm revoke`.

| Permission                                  | Impact if revoked                                             |
| ------------------------------------------- | ------------------------------------------------------------- |
| `android.permission.POST_NOTIFICATIONS`     | No push/status notifications; may affect ride status updates. |
| `android.permission.ACCESS_FINE_LOCATION`   | No precise location for pickup, routing, or scooters.         |
| `android.permission.ACCESS_COARSE_LOCATION` | No approximate location.                                      |
| `android.permission.BLUETOOTH_CONNECT`      | No Bluetooth connection access.                               |
| `android.permission.READ_EXTERNAL_STORAGE`  | No legacy external storage read access.                       |
| `android.permission.WRITE_EXTERNAL_STORAGE` | No legacy external storage write access.                      |
| `android.permission.READ_PHONE_STATE`       | No phone state access.                                        |
| `android.permission.CALL_PHONE`             | App cannot directly call driver/support.                      |
| `android.permission.CAMERA`                 | No QR/scanning/photo features.                                |
| `android.permission.RECORD_AUDIO`           | No microphone access.                                         |
| `android.permission.READ_CONTACTS`          | No contacts access.                                           |
| `android.permission.BLUETOOTH_SCAN`         | No Bluetooth scanning.                                        |

### Observed Runtime Behavior

After a no-login launch through the launcher activity, the app started
successfully. No fatal `ru.yandex.taxi` crash was found in the checked logcat
window.

Active processes:

- main process: `ru.yandex.taxi`;
- account process: `ru.yandex.taxi:passport`;
- analytics process/service: `ru.yandex.taxi:AppMetrica`;
- WebView sandbox process:
  `com.google.android.webview:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:0`.

Active services:

- `com.yandex.passport.internal.provider.communication.HostCommunicationService`;
- `io.appmetrica.analytics.internal.AppMetricaService`;
- `org.chromium.content.app.SandboxedProcessService0:0`.

Logcat showed foreground DNS/network activity for UID `10383`
(`ru.yandex.taxi`), including:

- `api.browser.yandex.ru:443`;
- `report.appmetrica.yandex.net:443`;
- `tools.messenger.yandex.net:443`;
- `authproxy.prod.yb.yandex.net:443`.

This is expected: Android's `restrict-background-blacklist` does not block
foreground traffic while the app is open.

The test device was already partially hardened before this guide was applied:
runtime permissions were `granted=false`, but `RUN_ANY_IN_BACKGROUND` was still
`allow`, UID `10383` was not in `restrict-background-blacklist`, and the
standby bucket became active after launch. The commands below are therefore a
reproducible strict profile, not a claim about the app's fresh-install state.

## Before You Start

Make sure ADB sees the device:

```bash
adb devices
```

Set variables and detect the app UID:

```bash
PACKAGE="ru.yandex.taxi"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Example from the tested device:

```text
appId=10383
```

Use your own value. Do not name this shell variable `UID`: in bash/zsh that
name is usually readonly.

```bash
APP_UID=10383
```

## Step 1: Revoke Runtime Permissions

This is a strict privacy profile. If you need a practical taxi profile, read
the exceptions section before applying it.

```bash
adb shell pm revoke "$PACKAGE" android.permission.POST_NOTIFICATIONS
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_CONNECT
adb shell pm revoke "$PACKAGE" android.permission.READ_EXTERNAL_STORAGE
adb shell pm revoke "$PACKAGE" android.permission.READ_PHONE_STATE
adb shell pm revoke "$PACKAGE" android.permission.CALL_PHONE
adb shell pm revoke "$PACKAGE" android.permission.CAMERA
adb shell pm revoke "$PACKAGE" android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm revoke "$PACKAGE" android.permission.RECORD_AUDIO
adb shell pm revoke "$PACKAGE" android.permission.READ_CONTACTS
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_SCAN
```

Some Android versions may report that a permission is not changeable or was not
requested. Continue with the next command.

Verify:

```bash
adb shell dumpsys package "$PACKAGE" | grep "granted=false"
```

## Step 2: Disable Advertising ID And AdServices

These settings are global. They affect all apps on the device, not only Yandex
Go.

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

AppOps are useful for behavior and permissions that cannot be cleanly removed
with `pm revoke`.

```bash
# Background execution
adb shell cmd appops set "$PACKAGE" RUN_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" RUN_ANY_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" START_FOREGROUND deny

# Scheduled jobs
adb shell cmd appops set "$PACKAGE" SCHEDULE_EXACT_ALARM deny

# Identifiers, account-like access, and phone state
adb shell cmd appops set "$PACKAGE" GET_ACCOUNTS deny
adb shell cmd appops set "$PACKAGE" READ_DEVICE_IDENTIFIERS deny
adb shell cmd appops set "$PACKAGE" READ_PHONE_STATE deny

# Clipboard and Wi-Fi state changes
adb shell cmd appops set "$PACKAGE" READ_CLIPBOARD deny
adb shell cmd appops set "$PACKAGE" CHANGE_WIFI_STATE deny

# Notifications
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny

# Full-screen intent, if available on your build
adb shell cmd appops set "$PACKAGE" USE_FULL_SCREEN_INTENT deny
```

On Android 15/16, some runtime-linked operations are also stored at UID level.
Add the UID-level form:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
adb shell cmd appops set --uid "$PACKAGE" ACTIVITY_RECOGNITION deny
```

Boot autostart depends on Android version:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

If the command returns `Unknown operation string: BOOT_COMPLETED`, treat
`RECEIVE_BOOT_COMPLETED` as not blockable through plain ADB AppOps on your
build.

Verify:

```bash
adb shell cmd appops get "$PACKAGE"
adb shell cmd appops get --uid "$PACKAGE"
```

Useful hardened lines:

```text
RUN_IN_BACKGROUND: deny
RUN_ANY_IN_BACKGROUND: deny
START_FOREGROUND: deny
READ_CLIPBOARD: deny
CHANGE_WIFI_STATE: deny
READ_DEVICE_IDENTIFIERS: deny
SCHEDULE_EXACT_ALARM: deny
POST_NOTIFICATION: deny
```

For runtime permissions revoked with `pm revoke`, Android can show mixed AppOps
state: UID mode `ignore` but package mode `allow`. Use `dumpsys package` as the
source of truth for actual runtime grant state.

## Step 4: Put The App In The `restricted` Standby Bucket

This moves the app into Android's strictest normal standby bucket.

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

Android can promote the bucket after active app use. On the tested device, the
bucket became active after launching Yandex Go. Re-run this after rides,
updates, or long foreground sessions.

## Step 5: Block Background Network

This blocks network only when Yandex Go is not in foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Verify:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Expected example:

```text
Restrict background blacklisted UIDs: 10383
```

Use your own UID, not `10383`, if your device shows a different value.

## All-In-One Script

Read the script before running it. It assumes the strictest ADB-only mode: no
notifications and no app location permission.

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="ru.yandex.taxi"
APP_UID="$(adb shell dumpsys package "$PACKAGE" | sed -n 's/.*appId=//p' | head -n 1 | tr -d '\r')"

if ! [[ "$APP_UID" =~ ^[0-9]+$ ]]; then
  echo "Error: Could not detect numeric APP_UID for $PACKAGE. Is the app installed?" >&2
  exit 1
fi

echo "[0/5] Package: $PACKAGE"
echo "[0/5] UID: $APP_UID"

echo "[1/5] Revoking runtime permissions"
RUNTIME_PERMS=(
  POST_NOTIFICATIONS
  ACCESS_FINE_LOCATION
  ACCESS_COARSE_LOCATION
  BLUETOOTH_CONNECT
  READ_EXTERNAL_STORAGE
  READ_PHONE_STATE
  CALL_PHONE
  CAMERA
  WRITE_EXTERNAL_STORAGE
  RECORD_AUDIO
  READ_CONTACTS
  BLUETOOTH_SCAN
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
  USE_FULL_SCREEN_INTENT
)

for op in "${APPOPS[@]}"; do
  adb shell cmd appops set "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op" \
    || echo "  skip: $op"
done

UID_APPOPS=(READ_PHONE_STATE POST_NOTIFICATION ACTIVITY_RECOGNITION)
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
adb shell cmd appops get "$PACKAGE" | grep -E "RUN_IN_BACKGROUND|RUN_ANY_IN_BACKGROUND|START_FOREGROUND|READ_CLIPBOARD|CHANGE_WIFI_STATE|READ_DEVICE_IDENTIFIERS|SCHEDULE_EXACT_ALARM|POST_NOTIFICATION"
```

## Optional: Practical Taxi Profile

The strict privacy profile may be inconvenient for real rides. A practical
compromise:

- keep `ACCESS_BACKGROUND_LOCATION` ungranted if future builds request it;
- allow `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` only "while using
  the app" through Android Settings;
- keep notifications if you need ride status, driver, pickup, and order changes;
- keep `CALL_PHONE` if you need direct calling from the app;
- keep camera only if you need QR/scooter/photo flows;
- keep restrictions on background execution, background network, exact alarms,
  identifiers, clipboard, and AdServices.

This is a usability compromise, not a requirement for every user.

## What Remains Without Root Or Shizuku

Some mechanisms remain outside plain ADB control:

| Mechanism                                           | Why it remains                                                                                                      |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Foreground network telemetry                        | Background netpolicy does not apply while the app is open.                                                          |
| AppMetrica service in foreground                    | No-login launch started `io.appmetrica.analytics.internal.AppMetricaService`.                                       |
| Yandex Passport process                             | No-login launch started `ru.yandex.taxi:passport` and Passport communication service.                               |
| WebView sandbox                                     | No-login launch started a Chromium/WebView sandbox process.                                                         |
| Install referrer permission                         | Google Play install-time permission.                                                                                |
| Account permissions                                 | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS`, and Yandex credential permissions are install-time.  |
| Boot permission                                     | `RECEIVE_BOOT_COMPLETED` may not be blockable through plain ADB AppOps on a given build.                            |
| `DETECT_SCREEN_CAPTURE` / `DETECT_SCREEN_RECORDING` | System-level permissions.                                                                                           |
| Foreground service types                            | Install-time declarations; runtime permissions can neutralize location access, but not the declarations themselves. |
| Component-level SDK providers/services              | Plain shell component disabling is restricted on modern Android and can easily break launch.                        |

For foreground telemetry control without root, the realistic next layer is a
local VPN firewall or DNS blocklist. Test that separately because domain
blocking can break maps, address search, login, payments, push, and ride
status.

## Rollback

Remove the background network restriction:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Restore standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Reset AppOps for the app:

```bash
adb shell cmd appops reset "$PACKAGE"
```

Restore AdServices sync and values if you intentionally disabled them globally:

```bash
adb shell device_config set_sync_disabled_for_tests none
adb shell device_config put adservices global_kill_switch false
adb shell device_config put adservices adid_kill_switch false
adb shell device_config put adservices measurement_kill_switch false
adb shell device_config put adservices adservice_enabled true
adb shell device_config put adservices adservice_system_service_enabled true
```

Runtime permissions can be granted again through Android Settings. Prefer
granting location only in "while using the app" mode.

## Conclusion

On Android 14-16 without root or Shizuku, Yandex Go can be meaningfully reduced:

- revoke dangerous runtime permissions;
- globally disable AdServices and Advertising ID;
- restrict background execution, exact alarms, clipboard, and identifiers;
- block background network by UID;
- put the app in standby bucket `restricted`.

This does not remove foreground telemetry and does not make taxi ordering fully
anonymous. It does reduce passive data collection when the app is closed or
idle, and it limits access to sensors, contacts, phone state, identifiers,
notifications, and location.

### Addendum: Wakelock issue

In Yandex Go/Taxi, as well as Navigator (`ru.yandex.yandexnavi`), there is often a bug or persistent telemetry feature where the application continues to poll GPS and hold wakelocks even after closing. You can restrict `WAKE_LOCK ignore` to fix battery drain issues related to this. Be careful with `RUN_IN_BACKGROUND ignore` if you rely on background trip monitoring.
