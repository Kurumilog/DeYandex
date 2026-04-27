# DeYandex: гайд по Yandex Eats

Пакет: `ru.foodfox.client`

Публичная идентификация пакета:

- Google Play использует `ru.foodfox.client` для Яндекс Еды:
  <https://play.google.com/store/apps/details?id=ru.foodfox.client>
- APK-зеркала также указывают этот package name для сборок Yandex Eats:
  <https://apkpure.com/%D1%8F%D0%BD%D0%B4%D0%B5%D0%BA%D1%81-%D0%B5%D0%B4%D0%B0-%D0%B4%D0%BE%D1%81%D1%82%D0%B0%D0%B2%D0%BA%D0%B0-%D0%B5%D0%B4%D1%8B/ru.foodfox.client>

Тестовое устройство:

- устройство: Samsung SM-S901E;
- Android: 16 / SDK 36;
- версия Yandex Eats: `26.15.0`;
- version code: `250000185`;
- UID приложения на тестовом устройстве: `10348`.

На вашем устройстве UID будет другим. Перед командами `netpolicy` всегда
получайте UID локально.

## Вступление

Yandex Eats чувствительнее обычного картографического приложения. Оно может
работать с адресами доставки, историей заказов, аккаунтом, телефоном,
push-уведомлениями, платежными сценариями, ресторанами/магазинами, курьерским
tracking, поддержкой и промо/referral-механиками. Задача hardening - сохранить
ручной сценарий заказа еды, но уменьшить пассивный сбор данных и фоновую
активность.

Гайд рассчитан на Android 14-16, ADB shell, без root, без Shizuku и без
перепаковки APK. Runtime-проверка была no-login: приложение запускалось и
наблюдалось, но вход в аккаунт, реальные адреса, корзина, оплата и оформление
заказа намеренно не тестировались.

## Цель

Цель - убрать все, что не нужно для базового использования Yandex Eats:

- без background location;
- без доступа к камере, микрофону и контактам по умолчанию;
- без уведомлений, если order-status alerts не нужны;
- без фоновой сети для UID приложения;
- меньше фонового выполнения и exact alarms;
- глобально отключенные Advertising ID и Google AdServices.

Для рабочего delivery-сценария foreground-сеть нужна. Foreground-геолокация
опциональна: она помогает выбирать адрес, но ручной ввод адреса приватнее.

## Что запрашивает Yandex Eats

Проверенная версия запрашивает меньше dangerous runtime permissions, чем Yandex
Maps, но содержит account, push, advertising, payment/deeplink, Firebase,
Adjust, AppMetrica и Yandex Passport интеграции.

### Install-time permissions, которые остаются `granted=true`

Эти разрешения были `granted=true` на тестовом Android 16. Большинство нельзя
отозвать через `pm revoke`.

| Разрешение | Почему важно |
|---|---|
| `android.permission.INTERNET` | Каталог, заказы, платежи, адреса, SDK-трафик, телеметрия. |
| `android.permission.ACCESS_NETWORK_STATE` | Проверка состояния сети. |
| `android.permission.ACCESS_WIFI_STATE` | Проверка состояния Wi-Fi. |
| `android.permission.CHANGE_WIFI_STATE` | Можно ограничить через AppOps. |
| `android.permission.WAKE_LOCK` | Может удерживать CPU активным для сервисов. |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Boot receivers; `BOOT_COMPLETED` AppOps был недоступен на тестовом Android 16. |
| `android.permission.FOREGROUND_SERVICE` | Foreground services. |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | Доступ к AdServices advertising ID. |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | Google attribution/measurement API. |
| `com.google.android.gms.permission.AD_ID` | Доступ к Google Advertising ID. |
| `com.google.android.c2dm.permission.RECEIVE` | Push-сообщения. |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking. |
| `android.permission.MANAGE_ACCOUNTS` | Интеграция аккаунтов. |
| `android.permission.AUTHENTICATE_ACCOUNTS` | Интеграция аккаунтов. |
| `android.permission.USE_CREDENTIALS` | Работа с credentials. |
| `com.yandex.permission.READ_CREDENTIALS.eda` | Интеграция Yandex Eats credentials. |
| `android.permission.READ_SYNC_SETTINGS` | Чтение настроек синхронизации. |
| `android.permission.WRITE_SYNC_SETTINGS` | Изменение настроек синхронизации. |
| `android.permission.DETECT_SCREEN_CAPTURE` | Детектирование скриншотов/захвата экрана. |
| `android.permission.DETECT_SCREEN_RECORDING` | Детектирование записи экрана. |
| `android.permission.NFC` | NFC-сценарии. |
| `android.permission.MODIFY_AUDIO_SETTINGS` | Управление аудио-поведением. |
| `android.permission.VIBRATE` | Вибрация и alerts. |
| `android.permission.USE_BIOMETRIC` | Биометрия для auth/payment/account flows. |
| `android.permission.USE_FINGERPRINT` | Legacy biometric flows. |

### Runtime permissions, которые можно отозвать

Эти разрешения были `granted=false` на тестовом устройстве. Это основная группа,
которую plain ADB может отозвать безопаснее всего.

| Разрешение | Что изменится после отзыва |
|---|---|
| `android.permission.POST_NOTIFICATIONS` | Не будет push/status notifications; может затронуть обновления по заказу. |
| `android.permission.ACCESS_FINE_LOCATION` | Не будет точной геолокации для адреса/курьерских функций. |
| `android.permission.ACCESS_COARSE_LOCATION` | Не будет примерной геолокации. |
| `android.permission.READ_MEDIA_VISUAL_USER_SELECTED` | Не будет доступа к выбранным visual media. |
| `android.permission.BLUETOOTH_CONNECT` | Не будет доступа к Bluetooth-подключениям. |
| `android.permission.CAMERA` | Не будут работать QR/фото-функции через камеру. |
| `android.permission.RECORD_AUDIO` | Не будет доступа к микрофону. |
| `android.permission.READ_CONTACTS` | Не будет доступа к контактам/referral-сценариям. |
| `android.permission.BLUETOOTH_SCAN` | Не будет Bluetooth-сканирования. |

### Наблюдаемое поведение после запуска

После no-login запуска приложение успешно стартовало. PID был активен, fatal
crash по Yandex Eats в проверенном окне logcat найден не был.

Foreground-процессы/сервисы:

- основной процесс: `ru.foodfox.client`;
- процесс аккаунта: `ru.foodfox.client:passport`;
- analytics process/service: `ru.foodfox.client:AppMetrica` /
  `io.appmetrica.analytics.internal.AppMetricaService`.

Основной процесс также подключался к Google Play Services, включая measurement
и location services. Published providers включали Firebase, Adjust,
AppMetrica/Yandex messaging/file providers, Yandex Passport providers и
несколько file providers.

Logcat показал foreground DNS/network activity для UID `10348`
(`ru.foodfox.client`), включая `yandex.ru:443`. Это ожидаемо:
`restrict-background-blacklist` блокирует только фоновую сеть, а не foreground
traffic, пока приложение открыто.

## Перед началом

Проверьте, что ADB видит устройство:

```bash
adb devices
```

Задайте пакет и получите UID:

```bash
PACKAGE="ru.foodfox.client"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Пример с тестового устройства:

```text
appId=10348
```

Используйте свое значение. Не называйте переменную `UID`: в bash/zsh это имя
обычно readonly.

```bash
APP_UID=10348
```

## Шаг 1: отозвать runtime permissions

Это strict privacy профиль. Если вам нужны уведомления по заказу, уберите
`POST_NOTIFICATIONS` из списка. Если нужна авто-геолокация адреса, оставьте
foreground location через настройки Android, но не выдавайте background
location.

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

На некоторых версиях Android команда может сообщить, что permission не
changeable или не запрошен. Продолжайте со следующей командой.

Проверка:

```bash
adb shell dumpsys package "$PACKAGE" | grep "granted=false"
```

## Шаг 2: отключить Advertising ID и AdServices

Эти настройки глобальные и влияют на все приложения, а не только на Yandex Eats.

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

Baseline Yandex Eats на тестовом устройстве показывал `READ_CLIPBOARD: allow`,
`RUN_ANY_IN_BACKGROUND: allow` и `WAKE_LOCK: allow`. Это хорошие цели для
ограничения.

```bash
# Фоновое выполнение
adb shell cmd appops set "$PACKAGE" RUN_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" RUN_ANY_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" START_FOREGROUND deny

# Запланированная работа
adb shell cmd appops set "$PACKAGE" SCHEDULE_EXACT_ALARM deny

# Идентификаторы и account-style access
adb shell cmd appops set "$PACKAGE" GET_ACCOUNTS deny
adb shell cmd appops set "$PACKAGE" READ_DEVICE_IDENTIFIERS deny
adb shell cmd appops set "$PACKAGE" READ_PHONE_STATE deny

# Clipboard и Wi-Fi state changes
adb shell cmd appops set "$PACKAGE" READ_CLIPBOARD deny
adb shell cmd appops set "$PACKAGE" CHANGE_WIFI_STATE deny

# Уведомления. Опционально: может сломать order-status alerts.
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny
```

На Android 15/16 добавьте UID-level ограничения для runtime-linked операций:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
```

Boot autostart зависит от версии:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

На тестовом Android 16 эта operation была недоступна для Yandex Maps. Если
Yandex Eats возвращает `Unknown operation string: BOOT_COMPLETED`, считайте
`RECEIVE_BOOT_COMPLETED` не блокируемым через plain ADB AppOps на этой прошивке.

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
```

## Шаг 4: перевести приложение в standby bucket `restricted`

Это ограничивает фоновые jobs и analytics scheduling, пока приложение idle.

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

На тестовом устройстве Yandex Eats уже находился в bucket `45`, но Android
может повысить bucket после активного использования или обновлений.

## Шаг 5: заблокировать фоновую сеть

Это блокирует сеть Yandex Eats только когда приложение не находится в
foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Проверка:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Ожидаемый пример:

```text
Restrict background blacklisted UIDs: 10348
```

Используйте свой UID.

## All-in-one script

Перед запуском прочитайте скрипт. Это strict privacy профиль: без геолокации
приложения и без уведомлений.

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

## Опционально: usable delivery profile

Для ежедневной доставки еды менее строгий профиль может быть практичнее:

- оставить background location отозванным;
- разрешить foreground location только "while using the app", если нужна
  авто-геолокация адреса;
- разрешить notifications только если нужны статусы заказа;
- оставить background network, background execution, exact alarms, identifiers,
  clipboard и AdServices ограниченными.

Ручной ввод адреса - более приватный default. Блокировка уведомлений лучше для
privacy, но делает tracking доставки менее удобным.

## Что остается без root или Shizuku

| Механизм | Почему остается |
|---|---|
| Foreground network telemetry | Background netpolicy не применяется, пока приложение открыто. |
| AppMetrica в foreground | Приложение запускало `io.appmetrica.analytics.internal.AppMetricaService` при no-login запуске. |
| Firebase / Adjust providers | Providers инициализируются приложением; plain ADB в этом гайде не отключает компоненты. |
| Account permissions | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS` и Yandex credential permissions являются install-time. |
| Payment/deeplink flows | Passport, Yandex Pay, SBP и внешние auth deeplinks - фичи приложения, не безопасные для удаления plain ADB. |
| Install referrer | Install-time permission Google Play. |
| Screen capture/recording detection | System-level permissions. |
| Boot receivers на некоторых прошивках | `BOOT_COMPLETED` AppOps может быть недоступен. |

Для контроля foreground-телеметрии без root следующий слой - локальный VPN
firewall или DNS blocklist. Это нужно тестировать отдельно: блокировка доменов
может ломать каталог, логин, адреса, оплату, поддержку и tracking заказа.

## Откат

Убрать ограничение фоновой сети:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Вернуть standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Сбросить AppOps:

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

Runtime permissions можно снова выдать через настройки Android. Для геолокации
лучше использовать режим "while using the app".

## Заключение

Yandex Eats можно заметно ужать без root:

- отозвать location, camera, microphone, contacts, Bluetooth, media и
  notification runtime permissions;
- глобально отключить AdServices и Advertising ID;
- ограничить background execution, exact alarms, clipboard access и
  identifier-style AppOps;
- перевести standby bucket в `restricted`;
- заблокировать фоновую сеть по UID приложения.

Это не удаляет foreground-телеметрию и SDK initialization, пока приложение
открыто. Но это снижает пассивный сбор данных, когда приложение закрыто или
простаивает, и ограничивает доступ к чувствительным sensors, account-adjacent
data, notifications, clipboard и background networking.
