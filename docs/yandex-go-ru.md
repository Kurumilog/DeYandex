# Яндекс Go / Такси (`ru.yandex.taxi`)

Приложение Яндекс Go запрашивает широкий спектр разрешений для управления аккаунтами и идентификации устройства, что позволяет строить детальный цифровой профиль.

## Рекомендуемые ограничения AppOps

### 1. Изоляция идентификаторов и вызовов

Блокировка доступа к IMEI/IMSI и списку аккаунтов на устройстве.

```sh
# Чтение статуса телефона и вызовы
adb shell cmd appops set ru.yandex.taxi READ_PHONE_STATE ignore
adb shell cmd appops set ru.yandex.taxi CALL_PHONE ignore

# Просмотр аккаунтов
adb shell cmd appops set ru.yandex.taxi GET_ACCOUNTS ignore
```

### 2. Ограничение фоновой активности

Если вы хотите, чтобы приложение работало только когда оно открыто.

```sh
adb shell cmd appops set ru.yandex.taxi RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.taxi WAKE_LOCK ignore
adb shell am set-standby-bucket ru.yandex.taxi restricted
```
