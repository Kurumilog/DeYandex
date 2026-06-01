# Яндекс Переводчик (`ru.yandex.translate`)

Несмотря на наличие офлайн-словарей, приложение постоянно связывается с серверами в фоновом режиме.

## Рекомендуемые ограничения AppOps

### 1. Остановка фоновой телеметрии

Переводчик должен работать только при активном экране.

```sh
adb shell cmd appops set ru.yandex.translate RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.translate WAKE_LOCK ignore
```

### 2. Защита буфера обмена

**Критически важно:** Запрещает приложению автоматически сканировать буфер обмена. Вам придется вручную вставлять текст, но это исключает утечку скопированных паролей.

```sh
adb shell cmd appops set ru.yandex.translate READ_CLIPBOARD ignore
```
