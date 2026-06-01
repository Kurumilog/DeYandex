# Yandex Market (`ru.beru.android`)

Yandex Market (formerly Beru) collects data about your contacts, Bluetooth environment, and uses aggressive AppMetrica analytics.

## Recommended AppOps Restrictions

### 1. Isolate Personal Data

Market requests access to contacts and Bluetooth scanning. This is not required for making purchases.

```sh
# Contacts
adb shell cmd appops set ru.beru.android READ_CONTACTS ignore

# Bluetooth
adb shell cmd appops set ru.beru.android BLUETOOTH_SCAN ignore
```

### 2. Isolate Sensors

```sh
adb shell cmd appops set ru.beru.android FINE_LOCATION ignore
adb shell cmd appops set ru.beru.android CAMERA ignore
adb shell cmd appops set ru.beru.android RECORD_AUDIO ignore
```

### 3. Restrict Background Activity

```sh
adb shell cmd appops set ru.beru.android RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.beru.android WAKE_LOCK ignore
adb shell am set-standby-bucket ru.beru.android restricted
```
