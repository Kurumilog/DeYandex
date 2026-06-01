# Yandex Go / Taxi (`ru.yandex.taxi`)

The Yandex Go app requests a wide range of permissions for account management and device identification, allowing for detailed digital profiling.

## Recommended AppOps Restrictions

### 1. Isolate Identifiers and Calls

Blocking access to IMEI/IMSI and the list of accounts on the device.

```sh
# Phone status and calls
adb shell cmd appops set ru.yandex.taxi READ_PHONE_STATE ignore
adb shell cmd appops set ru.yandex.taxi CALL_PHONE ignore

# Account access
adb shell cmd appops set ru.yandex.taxi GET_ACCOUNTS ignore
```

### 2. Restrict Background Activity

If you want the app to function only while it is open.

```sh
adb shell cmd appops set ru.yandex.taxi RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.taxi WAKE_LOCK ignore
adb shell am set-standby-bucket ru.yandex.taxi restricted
```
