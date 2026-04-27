# DeYandex: гайд по Yandex Go / Taxi

Пакет: `ru.yandex.taxi`

Пакет был найден на устройстве через список установленных приложений:

```text
package:.../ru.yandex.taxi-.../base.apk=ru.yandex.taxi installer=com.android.vending uid:10383
```

Launcher activity:

```text
ru.yandex.taxi/com.yandex.go.activity.alias.DefaultMainActivityAlias
```

Тестовое устройство:

- устройство: Samsung SM-S901E;
- Android: 16 / SDK 36;
- версия Yandex Go: `5.75.0`;
- version code: `50128094`;
- target SDK: `35`;
- UID приложения на тестовом устройстве: `10383`.

На вашем устройстве UID будет другим. Перед командами `netpolicy` всегда
получайте UID локально.

## Вступление

Yandex Go / Taxi чувствительнее обычного картографического приложения. Оно
работает с поездками, адресами, геолокацией, аккаунтом, платежными сценариями,
звонками, push-уведомлениями, Yandex Passport, Yandex Pay, WebView,
AppMetrica, картографическими SDK и deeplink-интеграциями. Часть этого нужна
для реального заказа такси, но не все нужно постоянно и не все должно работать
в фоне.

Гайд рассчитан на Android 14-16, ADB shell, без root, без Shizuku и без
перепаковки APK. Runtime-проверка была no-login: приложение запускалось, но
вход в аккаунт, реальные адреса, заказ поездки и платежи не тестировались.

## Цель

Цель - максимально ужать Yandex Go plain ADB-командами и оставить понятные
исключения для сценария реальной поездки.

Strict privacy профиль по умолчанию:

- без foreground/background location;
- без уведомлений;
- без камеры, микрофона, контактов и phone state;
- без прямого `CALL_PHONE`;
- без фоновой сети по UID;
- меньше фонового выполнения, exact alarms, clipboard и identifier access;
- глобально отключенные Advertising ID и Google AdServices.

Для реального заказа такси этот профиль может быть слишком строгим. Практичные
исключения описаны ниже: foreground location, notifications и прямой звонок
могут быть нужны для удобства и статуса поездки.

## Что запрашивает Yandex Go

Проверенная версия `5.75.0` запрашивает широкий набор permissions. Практически
их удобно делить на install-time permissions и runtime permissions.

### Install-time permissions, которые остаются `granted=true`

Эти разрешения были `granted=true` на тестовом Android 16. Большинство нельзя
отозвать через `pm revoke`, потому что Android выдает их при установке или они
относятся к SDK/system-интеграциям.

| Разрешение | Почему важно |
|---|---|
| `android.permission.INTERNET` | Поездки, карты, поиск адресов, платежи, SDK-трафик, реклама, телеметрия. |
| `android.permission.ACCESS_NETWORK_STATE` | Проверка состояния сети. |
| `android.permission.ACCESS_WIFI_STATE` | Проверка состояния Wi-Fi. |
| `android.permission.CHANGE_WIFI_STATE` | Можно ограничить через AppOps. |
| `android.permission.WAKE_LOCK` | Может удерживать CPU активным для задач и сервисов. |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Boot receivers; на тестовом Android 16 `BOOT_COMPLETED` AppOps может быть недоступен. |
| `android.permission.FOREGROUND_SERVICE` | Foreground services. |
| `android.permission.FOREGROUND_SERVICE_LOCATION` | Тип foreground-сервиса для геолокации. Реальный location access режется runtime location. |
| `android.permission.FOREGROUND_SERVICE_DATA_SYNC` | Foreground-сервис для синхронизации данных. |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | Доступ к AdServices advertising ID. |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | Google attribution/measurement API. |
| `com.google.android.gms.permission.AD_ID` | Доступ к Google Advertising ID. |
| `com.google.android.c2dm.permission.RECEIVE` | Push-сообщения. |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking. |
| `android.permission.MANAGE_ACCOUNTS` | Account / Passport integration. |
| `android.permission.AUTHENTICATE_ACCOUNTS` | Account / Passport integration. |
| `android.permission.USE_CREDENTIALS` | Работа с credentials. |
| `com.yandex.permission.READ_CREDENTIALS` | Yandex credentials. |
| `com.yandex.permission.AM_COMMUNICATION` | Yandex account manager communication. |
| `android.permission.READ_SYNC_SETTINGS` | Чтение настроек синхронизации. |
| `android.permission.WRITE_SYNC_SETTINGS` | Изменение настроек синхронизации. |
| `android.permission.DETECT_SCREEN_CAPTURE` | Детектирование скриншотов/захвата экрана. |
| `android.permission.DETECT_SCREEN_RECORDING` | Детектирование записи экрана. |
| `android.permission.NFC` | NFC/payment-adjacent сценарии. |
| `android.permission.MODIFY_AUDIO_SETTINGS` | Аудио-поведение приложения. |
| `android.permission.VIBRATE` | Вибрация и alerts. |
| `android.permission.USE_BIOMETRIC` | Биометрия для auth/payment/account flows. |
| `android.permission.USE_FINGERPRINT` | Legacy biometric flows. |
| `android.permission.USE_FULL_SCREEN_INTENT` | Full-screen notification intent; на тестовом устройстве AppOps был `deny`. |
| `com.android.vending.BILLING` | In-app billing. |
| `ru.yandex.taxi.ORDER_NOTIFICATION` | Собственное permission для уведомлений/заказов. |
| `ru.yandex.taxi.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Собственное permission для dynamic receivers. |
| `com.yandex.yphone.permission.READ` / `WRITE` | Yandex phone integration. |
| launcher badge permissions | Badge counters для Samsung/Huawei/Oppo/HTC/Sony launchers. |

### Runtime permissions, которые можно отозвать

Эти разрешения были `granted=false` на тестовом устройстве. Это основная
группа, которую plain ADB может отозвать через `pm revoke`.

| Разрешение | Что изменится после отзыва |
|---|---|
| `android.permission.POST_NOTIFICATIONS` | Не будет push/status notifications; может затронуть статус поездки. |
| `android.permission.ACCESS_FINE_LOCATION` | Не будет точной геолокации для подачи, маршрута и самокатов. |
| `android.permission.ACCESS_COARSE_LOCATION` | Не будет примерной геолокации. |
| `android.permission.BLUETOOTH_CONNECT` | Не будет доступа к Bluetooth-подключениям. |
| `android.permission.READ_EXTERNAL_STORAGE` | Legacy-доступ к внешнему хранилищу. |
| `android.permission.WRITE_EXTERNAL_STORAGE` | Legacy-запись во внешнее хранилище. |
| `android.permission.READ_PHONE_STATE` | Не будет доступа к phone state. |
| `android.permission.CALL_PHONE` | Приложение не сможет напрямую звонить водителю/поддержке. |
| `android.permission.CAMERA` | Не будут работать QR/сканирование/фото-сценарии. |
| `android.permission.RECORD_AUDIO` | Не будет доступа к микрофону. |
| `android.permission.READ_CONTACTS` | Не будет доступа к контактам. |
| `android.permission.BLUETOOTH_SCAN` | Не будет Bluetooth-сканирования. |

### Наблюдаемое поведение после no-login запуска

После запуска через launcher activity приложение стартовало без входа в
аккаунт. Fatal crash по `ru.yandex.taxi` в проверенном окне logcat найден не
был.

Активные процессы:

- основной процесс: `ru.yandex.taxi`;
- процесс аккаунта: `ru.yandex.taxi:passport`;
- analytics process/service: `ru.yandex.taxi:AppMetrica`;
- WebView sandbox process:
  `com.google.android.webview:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:0`.

Активные сервисы:

- `com.yandex.passport.internal.provider.communication.HostCommunicationService`;
- `io.appmetrica.analytics.internal.AppMetricaService`;
- `org.chromium.content.app.SandboxedProcessService0:0`.

Logcat показал foreground DNS/network activity для UID `10383`
(`ru.yandex.taxi`), включая:

- `api.browser.yandex.ru:443`;
- `report.appmetrica.yandex.net:443`;
- `tools.messenger.yandex.net:443`;
- `authproxy.prod.yb.yandex.net:443`.

Это ожидаемо: `restrict-background-blacklist` не блокирует foreground-трафик,
пока приложение открыто.

Текущее состояние до применения этого гайда уже было частично hardened на
тестовом устройстве: runtime permissions были `granted=false`, но `RUN_ANY_IN_BACKGROUND`
оставался `allow`, UID `10383` не был в `restrict-background-blacklist`, а
standby bucket после запуска стал активным. Поэтому команды ниже оформлены как
воспроизводимый strict-профиль, а не как описание исходного заводского состояния.

## Перед началом

Проверьте, что ADB видит устройство:

```bash
adb devices
```

Задайте пакет и получите UID:

```bash
PACKAGE="ru.yandex.taxi"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Пример с тестового устройства:

```text
appId=10383
```

Используйте свое значение. Не называйте переменную `UID`: в bash/zsh это имя
обычно readonly.

```bash
APP_UID=10383
```

## Шаг 1: отозвать runtime permissions

Это strict privacy профиль. Если вам нужен рабочий taxi-сценарий, прочитайте
раздел про исключения ниже перед применением.

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

На некоторых версиях Android команда может сообщить, что permission не
changeable или не запрошен. Продолжайте со следующей командой.

Проверка:

```bash
adb shell dumpsys package "$PACKAGE" | grep "granted=false"
```

## Шаг 2: отключить Advertising ID и AdServices

Эти настройки глобальные и влияют на все приложения, а не только на Yandex Go.

```bash
adb shell settings put secure advertising_id "00000000-0000-0000-0000-000000000000"

adb shell device_config put adservices global_kill_switch true
adb shell device_config put adservices adid_kill_switch true
adb shell device_config put adservices measurement_kill_switch true
adb shell device_config put adservices adservice_enabled false
adb shell device_config put adservices adservice_system_service_enabled false

adb shell device_config set_sync_disabled_for_tests persistent
```

Проверка:

```bash
adb shell settings get secure advertising_id
adb shell device_config get adservices global_kill_switch
adb shell device_config get adservices adid_kill_switch
adb shell device_config get adservices measurement_kill_switch
adb shell device_config get adservices adservice_enabled
adb shell device_config get adservices adservice_system_service_enabled
adb shell device_config get_sync_disabled_for_tests
```

Ожидаемые hardened-значения:

```text
00000000-0000-0000-0000-000000000000
true
true
true
false
false
persistent
```

## Шаг 3: ограничить AppOps

AppOps полезны для поведения и разрешений, которые нельзя чисто убрать через
`pm revoke`.

```bash
# Фоновое выполнение
adb shell cmd appops set "$PACKAGE" RUN_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" RUN_ANY_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" START_FOREGROUND deny

# Запланированные задачи
adb shell cmd appops set "$PACKAGE" SCHEDULE_EXACT_ALARM deny

# Идентификаторы, аккаунтоподобные данные и phone state
adb shell cmd appops set "$PACKAGE" GET_ACCOUNTS deny
adb shell cmd appops set "$PACKAGE" READ_DEVICE_IDENTIFIERS deny
adb shell cmd appops set "$PACKAGE" READ_PHONE_STATE deny

# Буфер обмена и изменение Wi-Fi state
adb shell cmd appops set "$PACKAGE" READ_CLIPBOARD deny
adb shell cmd appops set "$PACKAGE" CHANGE_WIFI_STATE deny

# Уведомления
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny

# Full-screen intent, если операция доступна на вашей прошивке
adb shell cmd appops set "$PACKAGE" USE_FULL_SCREEN_INTENT deny
```

На Android 15/16 некоторые runtime-linked операции также хранятся на UID-level.
Добавьте UID-level форму:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
adb shell cmd appops set --uid "$PACKAGE" ACTIVITY_RECOGNITION deny
```

Автозапуск после boot зависит от версии Android:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

Если команда возвращает `Unknown operation string: BOOT_COMPLETED`, считайте
`RECEIVE_BOOT_COMPLETED` не блокируемым через plain ADB AppOps на вашей
прошивке.

Проверка:

```bash
adb shell cmd appops get "$PACKAGE"
adb shell cmd appops get --uid "$PACKAGE"
```

Полезные hardened-строки:

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

Для runtime permissions, которые были отозваны через `pm revoke`, Android может
показывать смешанную картину в AppOps: UID mode `ignore`, но package mode
`allow`. Для фактического runtime grant state ориентируйтесь на
`dumpsys package`.

## Шаг 4: перевести приложение в standby bucket `restricted`

Это переводит приложение в самый строгий обычный standby bucket Android.

```bash
adb shell am set-standby-bucket "$PACKAGE" restricted
```

Проверка:

```bash
adb shell am get-standby-bucket "$PACKAGE"
```

Ожидаемо:

```text
45
```

Android может повысить bucket после активного использования приложения. После
запуска Yandex Go на тестовом устройстве bucket стал активным, поэтому команду
стоит повторять после поездок, обновлений или долгой foreground-сессии.

## Шаг 5: заблокировать фоновую сеть

Это блокирует сеть только тогда, когда Yandex Go не находится в foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Проверка:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Ожидаемый пример:

```text
Restrict background blacklisted UIDs: 10383
```

Используйте свой UID, а не `10383`, если ваше устройство показывает другое
значение.

## All-in-one script

Перед запуском прочитайте скрипт. Он предполагает максимально строгий ADB-only
режим: без уведомлений и без геолокации приложения.

```bash
#!/usr/bin/env bash
set -u

PACKAGE="ru.yandex.taxi"
APP_UID="$(adb shell dumpsys package "$PACKAGE" | sed -n 's/.*appId=//p' | head -n 1 | tr -d '\r')"

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

## Опционально: рабочий taxi-профиль

Для реальной поездки strict privacy профиль может быть неудобен. Практичный
компромисс:

- оставить `ACCESS_BACKGROUND_LOCATION` невыданным, если приложение его
  запросит в будущих версиях;
- разрешить `ACCESS_FINE_LOCATION` или `ACCESS_COARSE_LOCATION` только
  "while using the app" через настройки Android;
- оставить уведомления, если нужны статус поездки, водитель, посадка и
  изменения заказа;
- оставить `CALL_PHONE`, если нужен прямой звонок из приложения;
- оставить камеру только если нужны QR/самокатные/фото-сценарии;
- сохранить ограничения на background execution, background network, exact
  alarms, identifiers, clipboard и AdServices.

Это компромисс удобства, а не требование для всех пользователей.

## Что остается без root или Shizuku

Некоторые вещи остаются вне контроля plain ADB:

| Механизм | Почему остается |
|---|---|
| Foreground network telemetry | Background netpolicy не применяется, пока приложение открыто. |
| AppMetrica service в foreground | No-login запуск поднимал `io.appmetrica.analytics.internal.AppMetricaService`. |
| Yandex Passport process | No-login запуск поднимал `ru.yandex.taxi:passport` и Passport communication service. |
| WebView sandbox | No-login запуск поднимал Chromium/WebView sandbox process. |
| Install referrer permission | Install-time permission Google Play. |
| Account permissions | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS` и Yandex credential permissions являются install-time. |
| Boot permission | `RECEIVE_BOOT_COMPLETED` может быть не блокируемым через plain ADB AppOps на конкретной прошивке. |
| `DETECT_SCREEN_CAPTURE` / `DETECT_SCREEN_RECORDING` | System-level permissions. |
| Foreground service types | Install-time declarations; runtime permissions могут нейтрализовать location access, но не сами declarations. |
| Component-level SDK providers/services | Plain shell component disabling ограничен на современных Android и легко ломает запуск. |

Для контроля foreground-телеметрии без root реалистичный следующий слой -
локальный VPN firewall или DNS blocklist. Это нужно тестировать отдельно,
потому что блокировка доменов может ломать карты, поиск адресов, логин,
платежи, push и статус поездки.

## Откат

Убрать ограничение фоновой сети:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Вернуть standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Сбросить AppOps для приложения:

```bash
adb shell cmd appops reset "$PACKAGE"
```

Вернуть AdServices sync и значения, если вы осознанно отключали их глобально:

```bash
adb shell device_config set_sync_disabled_for_tests none
adb shell device_config put adservices global_kill_switch false
adb shell device_config put adservices adid_kill_switch false
adb shell device_config put adservices measurement_kill_switch false
adb shell device_config put adservices adservice_enabled true
adb shell device_config put adservices adservice_system_service_enabled true
```

Runtime permissions можно снова выдать через настройки Android. По возможности
выдавайте геолокацию только в режиме "while using the app".

## Заключение

На Android 14-16 без root и Shizuku Yandex Go можно заметно ужать:

- отозвать dangerous runtime permissions;
- глобально отключить AdServices и Advertising ID;
- ограничить background execution, exact alarms, clipboard и identifiers;
- заблокировать фоновую сеть по UID;
- перевести приложение в standby bucket `restricted`.

Это не удаляет foreground-телеметрию и не делает заказ такси полностью
анонимным. Но это снижает пассивный сбор данных, когда приложение закрыто или
простаивает, и ограничивает доступ к сенсорам, контактам, phone state,
идентификаторам, уведомлениям и геолокации.
