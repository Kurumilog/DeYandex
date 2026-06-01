# Яндекс Карты (`ru.yandex.yandexmaps`)

Яндекс Карты активно отслеживают физическую активность пользователя и статус телефона в фоновом режиме.

## Рекомендуемые ограничения AppOps

### 1. Блокировка отслеживания активности

Запрещает приложению понимать, идете ли вы пешком или едете на транспорте, без вашего ведома.

```sh
adb shell cmd appops set ru.yandex.yandexmaps ACTIVITY_RECOGNITION ignore
adb shell cmd appops set ru.yandex.yandexmaps READ_PHONE_STATE ignore
```

### 2. Ограничение ресурсов

Ограничивает фоновую телеметрию приложениия.

```sh
adb shell am set-standby-bucket ru.yandex.yandexmaps restricted
```
