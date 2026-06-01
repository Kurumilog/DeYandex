
## Research Summary & Targeted Commands
Based on the deep research provided by the user:

- **Browser (`com.yandex.browser`)**: Heavy bloatware/tracker.
  - `RUN_IN_BACKGROUND ignore`, `RUN_ANY_IN_BACKGROUND ignore`, `WAKE_LOCK ignore`
  - `ACCESS_FINE_LOCATION ignore`, `CAMERA ignore`, `RECORD_AUDIO ignore`, `READ_CLIPBOARD ignore`
- **Market (`ru.yandex.market`)**:
  - `RUN_IN_BACKGROUND ignore`, `WAKE_LOCK ignore`, `ACCESS_FINE_LOCATION ignore`
- **Music (`ru.yandex.music`)**: High battery drain.
  - `WAKE_LOCK ignore` (careful on old devices), `ACCESS_FINE_LOCATION ignore`, `CAMERA ignore`
- **Mail (`ru.yandex.mail`)**: Background sync and telemetry.
  - `RUN_IN_BACKGROUND ignore`, `WAKE_LOCK ignore`, `READ_CONTACTS ignore`
- **Search / Start (`ru.yandex.searchplugin`)**: Bloatware. Best to uninstall.
  - `pm uninstall -k --user 0 ru.yandex.searchplugin` or `pm disable-user`
  - If kept: `RUN_ANY_IN_BACKGROUND ignore`, `WAKE_LOCK ignore`, `ACCESS_FINE_LOCATION ignore`
- **Navigator (`ru.yandex.yandexnavi`)**: KeepAliveService issue.
  - `RUN_IN_BACKGROUND ignore` (careful if background nav needed), `CAMERA ignore` (AR), `RECORD_AUDIO ignore` (Alice), `WAKE_LOCK ignore` (fixes sticky GPS icon)
- **Translate (`ru.yandex.translate`)**: Offline claims but phones home.
  - `RUN_IN_BACKGROUND ignore`, `WAKE_LOCK ignore`, `READ_CLIPBOARD ignore`

Next up: writing the single interactive bash script (`scripts/deyandex.sh`) and updating docs.
- Created `scripts/deyandex.sh`, a unified interactive bash script that probes for connected devices, checks if each targeted package is installed, asks user permission via CLI prompts in English/Russian, and applies the `adb shell cmd appops` commands accordingly.
