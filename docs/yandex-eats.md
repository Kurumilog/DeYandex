# DeYandex Guide: Yandex Eats

Package: `ru.foodfox.client`

Public package identity:

- Google Play lists `ru.foodfox.client` for Yandex Eats:
  <https://play.google.com/store/apps/details?id=ru.foodfox.client>
- APK mirrors also list the same package name for Yandex Eats builds:
  <https://apkpure.com/%D1%8F%D0%BD%D0%B4%D0%B5%D0%BA%D1%81-%D0%B5%D0%B4%D0%B0-%D0%B4%D0%BE%D1%81%D1%82%D0%B0%D0%B2%D0%BA%D0%B0-%D0%B5%D0%B4%D1%8B/ru.foodfox.client>

Tested reference device:

- Device: Samsung SM-S901E
- Android: 16 / SDK 36
- Yandex Eats version: `26.15.0`
- Version code: `250000185`
- App UID on the tested device: `10348`

Your UID will be different. Always detect it locally before running network
policy commands.

## Introduction

Yandex Eats is more sensitive than a simple map app. It can expose or process
delivery addresses, order history, phone/account identity, push notifications,
payment flows, restaurant/store browsing, courier tracking, support chat, and
promo/referral behavior. The privacy goal is to keep the app usable for manual
food delivery flows while reducing passive collection and background activity.

This guide is based on Android 14-16, ADB shell, no root, no Shizuku, and no
APK repackaging. The tested runtime pass was no-login: the app was launched and
observed, but account login, real addresses, cart, payment, and order placement
were intentionally not tested.

## Goal

The goal is to remove everything that is not strictly needed for basic Yandex
Eats usage:

- no background location;
- no camera/microphone/contact access by default;
- no notification permission unless order-status alerts are desired;
- no background network for the app UID;
- reduced background execution and exact alarms;
- Advertising ID and Google AdServices disabled globally.

For a usable delivery flow, foreground network is required. Foreground location
is optional: it can help address selection, but manual address entry should be
preferred when privacy matters.

## What Yandex Eats Requests

The tested build requests fewer dangerous runtime permissions than Yandex Maps,
but it still contains account, push, advertising, payment/deeplink, Firebase,
Adjust, AppMetrica, and Yandex Passport integrations.

### Install-Time Permissions Still Granted

These were `granted=true` on the tested Android 16 device. Most cannot be
revoked with `pm revoke`.

| Permission | Why it matters |
|---|---|
| `android.permission.INTERNET` | Required for catalog, orders, payments, maps/address lookup, SDK traffic, telemetry. |
| `android.permission.ACCESS_NETWORK_STATE` | Lets the app inspect network state. |
| `android.permission.ACCESS_WIFI_STATE` | Lets the app inspect Wi-Fi state. |
| `android.permission.CHANGE_WIFI_STATE` | Can be restricted with AppOps. |
| `android.permission.WAKE_LOCK` | Lets services keep CPU awake. |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Allows boot-time receivers; `BOOT_COMPLETED` AppOps was unavailable on tested Android 16. |
| `android.permission.FOREGROUND_SERVICE` | Enables foreground services. |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | AdServices advertising ID access. |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | Google attribution/measurement API. |
| `com.google.android.gms.permission.AD_ID` | Google Advertising ID access. |
| `com.google.android.c2dm.permission.RECEIVE` | Push messaging. |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking. |
| `android.permission.MANAGE_ACCOUNTS` | Account integration. |
| `android.permission.AUTHENTICATE_ACCOUNTS` | Account integration. |
| `android.permission.USE_CREDENTIALS` | Account credentials integration. |
| `com.yandex.permission.READ_CREDENTIALS.eda` | Yandex Eats credential integration. |
| `android.permission.READ_SYNC_SETTINGS` | Sync integration. |
| `android.permission.WRITE_SYNC_SETTINGS` | Sync integration. |
| `android.permission.DETECT_SCREEN_CAPTURE` | Screen capture detection. |
| `android.permission.DETECT_SCREEN_RECORDING` | Screen recording detection. |
| `android.permission.NFC` | NFC-related flows. |
| `android.permission.MODIFY_AUDIO_SETTINGS` | Audio/session behavior. |
| `android.permission.VIBRATE` | Haptics and alerts. |
| `android.permission.USE_BIOMETRIC` | Biometric auth/payment/account flows. |
| `android.permission.USE_FINGERPRINT` | Legacy biometric flows. |

### Runtime Permissions Revoked On Tested Device

These were `granted=false` on the tested device. They are the main permissions
that plain ADB can revoke safely.

| Permission | Impact if revoked |
|---|---|
| `android.permission.POST_NOTIFICATIONS` | No push/status notifications; may affect order updates. |
| `android.permission.ACCESS_FINE_LOCATION` | No precise location for address detection or courier/location features. |
| `android.permission.ACCESS_COARSE_LOCATION` | No approximate location. |
| `android.permission.READ_MEDIA_VISUAL_USER_SELECTED` | No selected visual media access. |
| `android.permission.BLUETOOTH_CONNECT` | No Bluetooth device connection access. |
| `android.permission.CAMERA` | No QR/photo camera features. |
| `android.permission.RECORD_AUDIO` | No microphone access. |
| `android.permission.READ_CONTACTS` | No contact/referral access. |
| `android.permission.BLUETOOTH_SCAN` | No Bluetooth scanning. |

### Observed Runtime Behavior

After a no-login launch, the app started successfully. PID was present and no
fatal Yandex Eats crash was observed in the checked logcat window.

Foreground processes/services included:

- main process: `ru.foodfox.client`;
- account process: `ru.foodfox.client:passport`;
- analytics process/service: `ru.foodfox.client:AppMetrica` /
  `io.appmetrica.analytics.internal.AppMetricaService`.

The main process also connected to Google Play Services components including
measurement and location services. Published providers included Firebase,
Adjust, AppMetrica/Yandex messaging/file providers, Yandex Passport providers,
and several file providers.

Logcat showed foreground DNS/network activity for UID `10348`
(`ru.foodfox.client`), including `yandex.ru:443`. This is expected:
`restrict-background-blacklist` only blocks background network, not foreground
traffic while the app is open.

## Before You Start

Make sure ADB sees the device:

```bash
adb devices
```

Set the package variable and detect the app UID:

```bash
PACKAGE="ru.foodfox.client"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Example from the tested device:

```text
appId=10348
```

Use your own value. Do not name this shell variable `UID`: in bash/zsh that
name is usually readonly.

```bash
APP_UID=10348
```

## Step 1: Revoke Runtime Permissions

This is the strict privacy profile. If you rely on order push notifications,
remove `POST_NOTIFICATIONS` from the list. If you rely on automatic address
detection, keep foreground location enabled through Android Settings instead of
granting background location.

```bash
adb shell pm revoke "$PACKAGE" android.permission.POST_NOTIFICATIONS
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_VISUAL_USER_SELECTED
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_CONNECT
adb shell pm revoke "$PACKAGE" android.permission.CAMERA
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

These settings are global and affect all apps, not only Yandex Eats.

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

Yandex Eats baseline on the tested device showed `READ_CLIPBOARD: allow`,
`RUN_ANY_IN_BACKGROUND: allow`, and `WAKE_LOCK: allow`. These are good
hardening targets.

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

# Notifications. Optional: this can break order-status alerts.
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny
```

On Android 15/16, add UID-level restrictions for runtime-linked operations:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
```

Boot autostart is version-dependent:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

On the tested Android 16 build this operation was unavailable for Yandex Maps.
If Yandex Eats returns `Unknown operation string: BOOT_COMPLETED`, treat
`RECEIVE_BOOT_COMPLETED` as not blockable through plain ADB AppOps on that
build.

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

## Step 4: Restrict Standby Bucket

This limits background jobs and analytics scheduling while the app is idle.

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

The tested device already had Yandex Eats in bucket `45`, but Android may
promote it back after active use or updates.

## Step 5: Block Background Network Access

This blocks Yandex Eats network only when the app is not in foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Verify:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Expected example:

```text
Restrict background blacklisted UIDs: 10348
```

Use your own UID.

## All-In-One Script

Review before running. This is the strict privacy profile: no app location and
no notifications.

```bash
#!/usr/bin/env bash
set -u

PACKAGE="ru.foodfox.client"
APP_UID="$(adb shell dumpsys package "$PACKAGE" | sed -n 's/.*appId=//p' | head -n 1 | tr -d '\r')"

echo "[0/5] Package: $PACKAGE"
echo "[0/5] UID: $APP_UID"

echo "[1/5] Revoking runtime permissions"
RUNTIME_PERMS=(
  POST_NOTIFICATIONS
  ACCESS_FINE_LOCATION
  ACCESS_COARSE_LOCATION
  READ_MEDIA_VISUAL_USER_SELECTED
  BLUETOOTH_CONNECT
  CAMERA
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
)

for op in "${APPOPS[@]}"; do
  adb shell cmd appops set "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op" \
    || echo "  skip: $op"
done

UID_APPOPS=(READ_PHONE_STATE POST_NOTIFICATION)
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

## Optional: Usable Delivery Profile

For day-to-day food delivery, a less strict profile may be more practical:

- keep background location revoked;
- allow foreground location only while using the app if you need address
  detection;
- allow notifications only if you need order-status updates;
- keep background network, background execution, exact alarms, identifiers,
  clipboard, and AdServices restricted.

Manual address entry is the more private default. Notification blocking is
safer for privacy, but it can make delivery tracking less convenient.

## What Remains Without Root Or Shizuku

| Mechanism | Why it remains |
|---|---|
| Foreground network telemetry | Background netpolicy does not apply while the app is open. |
| AppMetrica in foreground | The app started `io.appmetrica.analytics.internal.AppMetricaService` during no-login launch. |
| Firebase / Adjust providers | Providers are initialized by the app; plain ADB should not disable components in this guide. |
| Account permissions | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS`, and Yandex credential permissions are install-time. |
| Payment/deeplink flows | Passport, Yandex Pay, SBP, and external auth deeplinks are app features, not safely removable with plain ADB. |
| Install referrer | Install-time Google Play permission. |
| Screen capture/recording detection | System-level permissions. |
| Boot receivers on some builds | `BOOT_COMPLETED` AppOps may be unavailable. |

For foreground telemetry control without root, the next layer is a local VPN
firewall or DNS blocklist. That needs separate testing because blocking domains
can break catalog loading, login, address lookup, payments, support chat, and
order tracking.

## Reverting

Remove the background network restriction:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Reset standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Reset AppOps:

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

Runtime permissions can be granted again from Android Settings. Prefer "while
using the app" for location.

## Conclusion

Yandex Eats can be hardened meaningfully without root:

- revoke location, camera, microphone, contacts, Bluetooth, media, and
  notification runtime permissions;
- disable AdServices and Advertising ID globally;
- restrict background execution, exact alarms, clipboard access, and
  identifier-style AppOps;
- force standby bucket `restricted`;
- block background network by app UID.

This does not remove foreground telemetry or SDK initialization while the app
is open. It does reduce passive collection when the app is closed or idle and
limits access to sensitive sensors, account-adjacent data, notifications,
clipboard, and background networking.
