# Яндекс Переводчик (`ru.yandex.translate`)

Несмотря на наличие офлайн-словарей, приложение постоянно связывается с серверами в фоновом режиме.

## Рекомендуемые ограничения AppOps

### 1. Остановка фоновой телеметрии

Переводчик должен работать только при активном экране.

```sh
adb shell cmd appops set ru.yandex.translate RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.translate WAKE_LOCK ignore
```

### 2. Защита буфера обмена и системы

**Критически важно:** Запрещает приложению автоматически сканировать буфер обмена. Также блокируется доступ к Bluetooth и наложение окон.

```sh
# Буфер обмена
adb shell cmd appops set ru.yandex.translate READ_CLIPBOARD ignore

# Система и Bluetooth
adb shell cmd appops set ru.yandex.translate SYSTEM_ALERT_WINDOW ignore
adb shell cmd appops set ru.yandex.translate BLUETOOTH_SCAN ignore
```

### 3. Ограничение ресурсов

Переводит приложение в режим ожидания `restricted`.

```sh
adb shell am set-standby-bucket ru.yandex.translate restricted
```
