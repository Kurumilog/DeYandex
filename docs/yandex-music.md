# Yandex Music (`ru.yandex.music`)

Yandex Music often suffers from high battery drain because it holds audio wakelocks even after you pause playback. It also utilizes a dedicated `:Metrica` background process to upload listening analytics constantly.

## Recommended AppOps Restrictions

_Caution:_ Applying `RUN_IN_BACKGROUND ignore` might break background music playback on certain OEM devices (like MIUI/ColorOS). Therefore, we only target specific sensors and wakelocks.

### 1. Address Battery Drain (Wakelocks)

_Warning:_ On older Android versions, this might stop playback when the screen turns off. Test this on your device. If playback stutters, revert it using `allow`.

```sh
adb shell cmd appops set ru.yandex.music WAKE_LOCK ignore
```

### 2. Isolate Sensors (Location, Camera, Mic)

A music player does not need precise location profiling, camera access, or microphone access (unless you use in-app voice search) to stream audio.

```sh
adb shell cmd appops set ru.yandex.music FINE_LOCATION ignore
adb shell cmd appops set ru.yandex.music CAMERA ignore
adb shell cmd appops set ru.yandex.music RECORD_AUDIO ignore
```

### 3. Resource Restriction

Moves the app to the `restricted` standby bucket to limit background data transfers by the analytics SDK.

```sh
adb shell am set-standby-bucket ru.yandex.music restricted
```

## Russian Version

[yandex-music-ru.md](yandex-music-ru.md)
