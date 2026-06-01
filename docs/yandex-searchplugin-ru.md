# Яндекс Старт / Поиск (`ru.yandex.searchplugin`)

Этот пакет является предустановленным мусором (bloatware). Он дублирует функционал браузера и агрессивно профилирует поисковые запросы в фоне.

## Рекомендация: Удаление

Настоятельно рекомендуется полностью удалить этот пакет.

### Удаление (стирает из активного профиля пользователя):

```sh
adb shell pm uninstall -k --user 0 ru.yandex.searchplugin
```

### Заморозка (безопаснее, если удаление вызывает bootloop на MIUI):

```sh
adb shell pm disable-user --user 0 ru.yandex.searchplugin
```

## Ограничения AppOps (если удалить невозможно)

```sh
adb shell cmd appops set ru.yandex.searchplugin RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.searchplugin WAKE_LOCK ignore
adb shell cmd appops set ru.yandex.searchplugin ACCESS_FINE_LOCATION ignore
```
