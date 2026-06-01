# Yandex Start / Search (`ru.yandex.searchplugin`)

This package is often classified as OEM bloatware on devices adapted for the CIS market (Xiaomi, Samsung, Realme). It duplicates basic browser functionality, forces the "Zen" feed, and aggressively profiles search queries and location data in the background.

## Recommendation: Uninstall

It is highly recommended to uninstall or deeply disable this package entirely.

### Uninstall (removes from active user profile):

```sh
adb shell pm uninstall -k --user 0 ru.yandex.searchplugin
```

### Disable (safer if uninstalling causes bootloops on heavy OEM skins like MIUI):

```sh
adb shell pm disable-user --user 0 ru.yandex.searchplugin
```

## Recommended AppOps Restrictions (If forced to keep via MDM)

If you absolutely cannot uninstall it, isolate it completely:

```sh
adb shell cmd appops set ru.yandex.searchplugin RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set ru.yandex.searchplugin WAKE_LOCK ignore
adb shell cmd appops set ru.yandex.searchplugin ACCESS_FINE_LOCATION ignore
```

## Russian Version

[yandex-searchplugin-ru.md](yandex-searchplugin-ru.md)
