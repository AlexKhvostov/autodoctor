# ADR-001: мобильная архитектура Flutter

- **Статус:** Accepted
- **Дата:** 2026-07-16
- **Область:** `apps/mobile`

**Связанные документы:** [архитектура системы](../architecture.md) · [UX-flow](../ux-flow.md) · [модель данных](../data-model.md) · [ТЗ MVP v1.0](../../AutoDoctor_TZ_MVP.md)

## Контекст

Мобильный клиент AutoDoctor должен поддерживать один код для Android и iOS, публичный browse shell, гостевой сценарий без invite activation, коллекцию автомобилей, глобальную шапку и пять локализованных вкладок RU «План / Журнал / AI / Состояние / Ещё» и EN «Plan / Journal / AI / Condition / More», экран Состояния (`/state`), отдельный route Analytics (`/analytics`), redesign home Плана без rail расходников, compact history wizard, несколько AI-тем на машину, RU/EN локализацию с русским default/fallback, атомарный перенос гостевых данных при social auth, offline-чтение и очередь изменений, social auth deep links, а также предсказуемое тестирование критического flow. Внутренний route `/roadmap` и технические API/model names сохраняются.

Текущий [`apps/mobile/pubspec.yaml`](../../apps/mobile/pubspec.yaml) уже содержит `flutter_riverpod`, `go_router`, `dio`, `drift`, `flutter_secure_storage` и необходимые пакеты Drift code generation. Требуется зафиксировать единый подход до реализации вертикального среза.

Для ближайшего вертикального среза принят manual-first профиль: внешний VIN/AI provider не подключён, активной кнопки/route/sheet enrichment нет, а decode/confirm остаются только future contract. VIN и пробег необязательны; их отсутствие не блокирует профиль, но явно ограничивает будущую автоматизацию, точность идентификации комплектации и пробеговые сроки.

## Решение

Принять следующий стек и организацию:

- **Riverpod** — управление состоянием и внедрение зависимостей;
- **go_router** — декларативная навигация, redirects и deep links;
- **feature-first** — основная структура исходного кода по продуктовым возможностям;
- **Dio** — HTTP-клиент для JSON REST API;
- **Drift** — типизированная локальная SQLite БД, миграции, offline-cache и очередь синхронизации.
- **Flutter gen_l10n + ARB** — типобезопасные RU/EN ресурсы всех UI- и accessibility-строк с runtime-переключением.

```text
lib/
  app/                 # bootstrap, router, theme, localization
  core/                # network, database, sync, errors, shared primitives
  features/
    browse/
    onboarding/
    vehicle/
    roadmap/
    plan/
    journal/             # unified timeline presentation and add-event flow
    history/
    expenses/
    analytics/
    consumables/
    reminders/
    assistant/
    notifications/
    documents/
    profile/
    auth/
    settings/
    feedback/
```

Внутри крупной feature допускаются слои `presentation`, `application`, `domain`, `data`. Они вводятся только там, где разделяют UI, orchestration, модель предметной области и источники данных; пустые формальные слои не создаются. Межфункциональные зависимости проходят через интерфейсы/провайдеры из `core` либо публичный API feature.

### Локализация

- Поддерживаемые локали ограничены `ru` и `en`; русский является pilot default и конечным fallback.
- ARB-файлы являются источником всех пользовательских строк, включая semantics labels, hints и announcements; код обращается к сгенерированным `AppLocalizations`, а не к строковым литералам.
- Персистентная настройка имеет стабильные значения `system`, `ru`, `en`. Picker расположен в More/Settings, применяется немедленно через app-level locale state и не пересоздаёт router или бизнес-состояние.
- `system` нормализует системный locale до базового языка: `ru-*` → `ru`, `en-*` → `en`, иначе `ru`.
- Отображаемые строки не используются для route paths/names, provider/cache keys, enum serialization, analytics events или API machine codes. Пользовательские RU «План» / «План обслуживания» и EN `Plan` / `Maintenance plan` отображаются поверх неизменного `/roadmap`.
- Локализованные значения форматирования дат, чисел, единиц и валют создаются через locale-aware formatter на presentation boundary. BYN, регион Беларусь и технические единицы остаются структурированными значениями и не переводятся как labels.

## Обоснование

### Riverpod

- Поддерживает явный dependency graph без `BuildContext`.
- Удобен для async-состояний API/БД, scoped override в тестах и восстановления состояния после offline/online.
- Подходит для разделения server state, локального optimistic state и статуса синхронизации.

Провайдеры не должны содержать widget-навигацию или напрямую смешивать Dio и Drift. UI наблюдает состояние application-уровня, а репозитории координируют remote/local источники.

### go_router

- Корневой shell доступен публично и показывает browse-контент до создания сессии; invite activation отсутствует.
- Поддерживает callback/deep links для `telegram`, `google`, `apple`; token/code из callback передаётся backend exchange и не считается проверенным на клиенте.
- Guard-условия учитывают загрузку bootstrap, обязательные согласия и выбранный `active_vehicle_id`, но отсутствие автомобиля не закрывает routes shell: экран сам отображает preview/disabled-state.
- Использует `StatefulShellRoute` либо эквивалент для пяти устойчивых веток с локализованными подписями RU «План / Журнал / AI / Состояние / Ещё» и EN «Plan / Journal / AI / Condition / More»; AI визуально оформляется крупной центральной кнопкой, но остаётся полноценной веткой shell. Analytics — отдельный nested route `/analytics` из Плана и Ещё, не вкладка.
- Позволяет сохранять глобальную однострочную шапку над основными и вложенными маршрутами, а Garage/переключатель, панель AI-тем и detail sheet Состояния/расходников открывать как modal surface. Side-sheet занимает 80–85% ширины, содержит однораскрытый accordion.
- Возврат на вложенном экране относится к заголовку контента и не заменяет глобальную шапку.

Redirect не выполняет сетевую бизнес-операцию, не создаёт гостевую сессию и не обменивает social credential. Он принимает решение только по уже загруженному bootstrap/session/capabilities state, чтобы не создавать циклы и гонки. Deep-link callback сначала попадает на нейтральный auth route, application layer выполняет exchange, затем router реагирует на новое состояние.

### Feature-first

- Совпадает с продуктовой декомпозицией и позволяет независимо развивать вертикальные сценарии.
- Снижает связанность по сравнению с глобальными папками `screens/services/models`.
- Упрощает ownership, widget/integration tests и поэтапную поставку MVP.

Общие элементы переносятся в `core` только после появления реального повторного использования; feature не должна импортировать внутренние файлы другой feature.

### Dio

- Даёт единый pipeline для base URL, timeout, безопасного логирования, `request_id`, auth refresh и idempotency key.
- Поддерживает отмену запроса и единое преобразование API-ошибок в типизированные ошибки приложения.
- Не привязывает приложение к VIN- или AI-провайдеру: мобильный клиент обращается только к Laravel API.
- Добавляет активную нормализованную локаль в согласованное поле применимых запросов и `Accept-Language`; locale interceptor читает app-level locale state, а не локализованный display name.

После отдельной поставки AI backend транспорт использует обычный `POST` и получает полный ответ без streaming. Каждый запрос явно содержит неизменяемые `vehicle_id`, `conversation_id` и активную локаль; перехватчики обязаны исключать VIN, email, токены, номера документов, заметки и текст чата из логов. Текущий срез показывает `featureNotReady` при активном автомобиле и не отправляет AI-запросы. API применяет precedence `Accept-Language` → locale session → RU fallback и base-language normalization.

### Drift

- Даёт типобезопасные запросы, реактивное чтение и версионированные SQLite migrations.
- Подходит для последнего профиля и immutable maintenance snapshot, а также последующих реализованных feature caches и локальной очереди операций.
- Позволяет одинаково реализовать offline-очередь для гостевой и зарегистрированной сессии.

Drift не хранит пароль, API-ключи или refresh-token. Секреты находятся в `flutter_secure_storage`. Выбранный locale mode `system` / `ru` / `en` хранится как стабильная настройка интерфейса и восстанавливается до построения shell. После social auth сервер остаётся источником истины, а локальные UUID и операции гостя мигрируют/синхронизируются идемпотентно. Backend-проверка provider token/code и merge гостя составляют одну транзакцию. Email/password может быть отключён capabilities и не является обязательным MVP flow.

### Активный автомобиль и изоляция контекста

`active_vehicle_id` — персистентная клиентская настройка и не часть route как источник истины. После входа она синхронизируется с серверной пользовательской настройкой для восстановления между запусками, но клиентская проверка доступа и явный `vehicle_id` каждого запроса остаются обязательными. После bootstrap клиент загружает доступную коллекцию, сверяет сохранённый ID и выбирает первый доступный автомобиль только как fallback. Жёсткого лимита в клиентской модели нет; UI использует `max_vehicles_per_user` из `/capabilities` (пилотное значение по умолчанию `1`).

Все provider/repository/cache/query/offline-queue ключи для плана, роадмапа, Журнала, истории, расходов, аналитики, расходников, напоминаний, документов автомобиля и AI включают `vehicle_id`. AI-темы, сообщения и черновики дополнительно ключуются `conversation_id`. При переключении:

1. новый `active_vehicle_id` сохраняется локально;
2. обычные in-flight Dio-запросы прежнего контекста отменяются через `CancelToken`, где это возможно;
3. уже отправленный AI-запрос не переназначается: результат записывается только в cache исходных `vehicle_id` и `conversation_id` и не публикуется в UI другой машины;
4. scoped providers прежнего автомобиля инвалидируются, а новый контекст загружается независимо;
5. мутации сохраняют исходный `vehicle_id` и idempotency key, поэтому переключение не переназначает pending operation другому автомобилю;
6. список AI-тем, текущий чат и черновик переключаются одним scoped state и не используют сообщения других тем.

## Правила реализации

1. Репозиторий предоставляет feature единый поток локальных данных и скрывает, пришли они из Drift или Dio.
2. Remote-ответ сначала валидируется, затем транзакционно записывается в Drift; UI получает согласованное локальное состояние.
3. Изменение, разрешённое offline, сначала записывает сущность и `pending_operation` одной локальной транзакцией. Это правило действует и для гостя.
4. Создание manual profile, серверный пересчёт плана и AI требуют сети и не подменяются локальными предположениями; future VIN decode следует тому же правилу.
5. Каждая изменяющая API-операция получает UUID и idempotency key. Retry допускается только согласно классификации ошибки и backoff.
6. Конфликт отмечается локально и не приводит к молчаливой потере пользовательской записи. Последнее подтверждённое изменение применяется сервером и аудитируется.
7. Маршрут не является хранилищем бизнес-состояния; идентификаторы допустимы в path, данные загружаются через provider/repository.
8. Модели API, таблицы Drift и domain/view models не считаются одной моделью автоматически; преобразования явны на границах.
9. Все vehicle-scoped API вызовы явно содержат `vehicle_id`; клиент не полагается на «текущий автомобиль» на backend.
10. Создание гостевой сессии запускается только при первом действии, требующем записи (например, Add vehicle), а публичный browse shell не создаёт её автоматически.
11. Social auth callback обрабатывает `state`/nonce и PKCE там, где применимо; provider credential не логируется и отправляется только backend exchange endpoint.
12. Routes Плана обслуживания, Журнала, AI, Аналитики, «Ещё», Garage и всех вложенных форм доступны без `active_vehicle_id`; application layer не вызывает vehicle-scoped API, а отдаёт типизированное `noVehiclePreview` состояние. Мутации из этого состояния блокируются до выбора автомобиля.
13. Глобальная шапка принадлежит корневому shell и не дублируется feature-экранами. Она читает только агрегированные состояния активной машины, уведомлений и профиля; вложенный back обрабатывается заголовком контента.
14. Layout Плана обслуживания содержит fixed rail и independently scrollable timeline v3: persisted past service records всегда до current marker, затем future items по общему v3 comparator. Marker «Сейчас» стоит точно в конце displayed confirmed mileage fraction, а без mileage dynamics — confirmed time leg; фиксированный центр запрещён. Узел сохраняет component icon и показывает ровно два compact signals (`actionLevel`, `basis`) с одним общим legend.
15. `MileageForecastRepository` вызывает активный `GET /vehicles/{vehicleId}/mileage-forecast` и декодирует `default_assumption|empirical`, `low|medium|high`, observation count и localized estimate label. При <2 observations backend возвращает 10000 km/low. Клиент показывает forecast только как approximate next window и никогда не использует его для mileage, marker, overdue/status или notifications.
16. Топливная деталь расхода хранится структурированно: сумма, литры, цена за литр, пробег, полный бак и необязательная АЗС. Idempotency key обязателен, а признаки дедупликации сохраняются для будущего импорта без реализации loyalty в MVP.
17. `chatConversationProvider` и `chatDraftProvider` параметризуются `vehicle_id` и `conversation_id`. Общий технический контекст машины формирует backend; клиент не объединяет сообщения разных тем и не превращает содержимое беседы в подтверждённые данные без отдельной мутации пользователя.
18. Личные документы ключуются `user_id`, документы машины — `vehicle_id`. Полный номер не пишется в обычный Drift cache, логи или аналитику; при необходимости offline-показа хранится только маска, а секретные значения остаются на сервере.
19. Фото и сканы документов не моделируются в MVP. История уведомлений хранит метаданные события и область (`user` либо `vehicle`), но не полный номер документа.
20. Мобильный клиент получает только эффективную AI-конфигурацию и лимиты. Filament Playground, test connection, выбор provider/model, approved prompt, аудит и rollback являются backend/admin-функциями; секреты и A/B-распределение в клиент не попадают.
21. `journal` объединяет `service_record` и `expense` только во view model общей хронологии. Репозитории, таблицы Drift, мутации и правила синхронизации этих доменов остаются раздельными; фильтры «Все / Обслуживание / Заправки / Прочие расходы» применяются к типизированному объединённому потоку.
22. Действие «Добавить событие» и кнопка `+` открывают один vehicle-aware bottom sheet. «Обслуживание или ремонт» открывает `ServiceRecordScreen` с nullable `workCode`; global flow требует выбрать ровно одну работу, per-event/consumable `Произвёл` передаёт prefilled workCode. Today/current confirmed mileage — editable defaults. History wizard остаётся отдельным declaration flow.
23. `analytics` читает только подтверждённые локальные/серверные проекции активного автомобиля: суммы месяц/год, категории и точки пробега. Fuel consumption и связанный топливный forecast имеют явное состояние `insufficientData`; preview/empty state не создаёт фиктивные series или значения.
24. `consumables` остаётся read-only projection, но numeric condition data поступает из активных append-only `GET/POST condition-observations`. Expanded accordion держит максимум одну card и выделяет её отдельными theme background/border. Numeric subset: pads, discs, tires; клиент показывает server wear и read-only remaining отдельно, без fake %. Threshold status приходит из `maintenance-v3/condition-wear-v1`; клиент не вычисляет OEM remaining life или next due.
25. Problem assessment декодируется из типизированного backend DTO. Urgency, complexity и nullable cost — независимые значения 0–5 без вычисляемого общего score; confidence хранится отдельно. Cost DTO без проверенного region/date/source не принимается и не отображается.
26. Детерминированное критическое предупреждение приходит отдельным полем/состоянием, рендерится выше AI-ответа и не может быть понижено данными модели. Каждая доступная шкала имеет пять сегментов, текст и иконку; семантика доступна screen reader и не зависит только от цвета.
27. `RoadmapEventViewModel` либо эквивалент содержит дату/время или период, необязательный пробег, название, одну primary category для component icon и ровно два сигнала: `actionLevel` и `basis`. Source/history/category и исходные status/urgency/criticality/importance доступны в expanded detail, а не как badges.
28. `actionLevel` имеет `info|recommendation|attention|required|critical`; `basis` — `confirmed|forecast|missingData`. Mapping: `immediate|critical_attention` → critical; `high|overdue|requires_check_now` → required; `medium|soon` → attention; `recommended` → recommendation; остальные → info. Higher level wins.
29. Overdue без safety/immediate даёт `required`, не `critical`. Оба сигнала имеют icon + localized text + tooltip + semantics; цвет остаётся дополнительным каналом.
30. Timeline v3, rail и side-sheet строятся из maintenance-plan/timeline/consumables и persisted records. Plan/future timeline/consumables используют единый comparator: unresolved first, внутри safety/high first; затем resolved critical/overdue/soon/current по urgency/importance/earliest due; tie-break workCode/id. Forecast остаётся отдельным read model.
31. Rail и timeline объявляются отдельными semantic scroll regions. Side-sheet использует modal semantics, focus trap, явное закрытие, tap по scrim и системный Back; после закрытия focus возвращается на вызвавший rail item. Widget-тесты покрывают размеры, независимую прокрутку, отсутствие layout squeeze, focus/semantics и крупный системный шрифт.
32. Widget/unit-тесты покрывают component icons, пять action levels, три basis states, higher-wins mapping, localized tooltip/semantics и единый compact legend. Отдельно проверяются single-expand с distinct background/border, marker на конце preferred mileage/fallback time fraction, forecast-only next window, numeric wear/remaining, thresholds и отсутствие fake %.
33. App-level locale controller разрешает только `system`, `ru`, `en`, сохраняет выбор, вычисляет effective locale и немедленно обновляет `MaterialApp.router`/`CupertinoApp` без потери route, vehicle context и несохранённого ввода.
34. Все UI- и a11y-строки находятся в ARB и доступны через `gen_l10n`; lint/review запрещает пользовательские литералы и построение route/key/code из локализованного текста.
35. Locale interceptor передаёт effective locale и `Accept-Language` во всех применимых запросах. Guest session сохраняет выбранную локаль; клиент не интерпретирует локализованное API message как machine state.
36. Guest consent и error presentation выбирают RU/EN message при неизменных code, validation field keys и `request_id`.
37. AI presentation передаёт активную локаль, но safety warning моделируется отдельным стабильным enum/code. Одинаковые RU/EN симптомы должны давать один safety outcome; проверенная техническая цитата не переводится автоматически без утверждённого перевода.
38. Catalog/system-generated title view models разделяют стабильный identifier, locale и display text, чтобы будущая локализация не меняла identity или ссылки на источник.
39. Locale-aware formatters применяются на presentation boundary к датам, числам, единицам и валютам. Денежная модель хранит ISO currency code `BYN`, регион и числовое значение отдельно от локализованного отображения.
40. Widget/contract-тесты покрывают RU default/fallback, system base-language normalization, picker persistence/immediate apply, ARB/a11y coverage, header/session/fallback precedence, неизменность routes/codes и locale-aware formatting.
41. Добавление автомобиля — одна типизированная state machine: `/garage/add` → `/garage/add/vin` → `/garage/add/confirm` → online `POST /vehicles` → `/plan/first` (`loading|success|error`) → optional `/history/wizard` → `/roadmap`. Success означает реальный `by-pilot-baseline-2`; primary CTA уточняет историю, secondary пропускает wizard.
42. Draft ручного профиля хранится в application state, не содержит открытый VIN в Drift, analytics, breadcrumbs или Dio logs и очищается после успешного save/явной отмены. Для retry в памяти сохраняются payload и стабильный `Idempotency-Key`.
43. Форма использует закрытые DTO `ManualVehicleDraft`, `EngineDraft`, `TransmissionDraft`; неизвестные server fields не прокидываются обратно. Клиентская валидация повторяет UX, но backend валидирует итоговый объект после PATCH. Порядок draft/UI: make → model → production year → engine (displacement + fuel) → optional transmission → optional mileage → optional VIN → дополнительные сведения.
44. Матрица формы детерминирована: displacement required для `petrol/diesel/hybrid/lpg`, отсутствует/null для `electric`, optional для `other`; transmission целиком optional и MVP picker содержит только `manual|automatic`; gears optional без conditional requirement.
45. Кнопка, route и sheet «Собрать данные по VIN» отсутствуют. Поле VIN имеет локализованный helper о том, что будущий автоматический сбор и точная идентификация комплектации потребуют VIN. Future decode/confirm не включаются в router.
46. `VehicleDto` содержит nullable `vin_masked`, nullable `mileage`, nullable `transmission`, `profile_status`, `recommendation_scope`, явные manual fields, provenance только переданных полей и `version`. Полный VIN не моделируется в response/cache model.
47. После `POST /vehicles` ответ сохраняется локально, назначается `active_vehicle_id`, глобальная шапка обновляется и только затем открывается `/plan/first`. Повтор с тем же key не создаёт второй объект; `401/409/422` сохраняют draft.
48. Correction профиля использует allowlisted `UpdateVehicleRequest` с обязательным `version`. Current marker «Уточнить» использует отдельный `PUT /vehicles/{vehicleId}/mileage` с optimistic version и idempotency: optimistic UI откатывается при ошибке, успешный ответ атомарно публикует observation, vehicle mileage/version и новый plan snapshot. Это не service/expense/Journal event. Снижение требует отдельного confirmation+reason flow; mobile MVP может временно вернуть локализованный disallow-state.
49. Pending-review профиль допускает universal/type-level presentation и блокирует specific OEM regulation. Future enrichment моделируется отдельным draft proposal `field/proposedValue/source/sourceUrl/asOf/confidence`; применение требует explicit user accept.
50. Pilot make/model catalog поставляется как изменяемая клиентская конфигурация/read model: Volkswagen, Peugeot, Mitsubishi, BMW, Mercedes-Benz, Mazda и `Other`, с зависимыми моделями и `Other model`. DTO и Drift не превращают catalog values в enum; API принимает нормализованные строки до 100 символов.
51. UI production year использует dropdown `current year..1980`; DTO допускает более широкий API-диапазон. Отсутствующий mileage даёт типизированное состояние ограниченной точности без обещания точных пробеговых сроков; initial observation создаётся только при переданном mileage.
52. `MaintenancePlanRepository` принимает `vehicle_id` и effective locale, декодирует стабильные `work_code`/warning codes отдельно от локализованных `title`/`basis`, кеширует snapshot по `vehicle_id + snapshot_id` и атомарно обновляет plan/timeline/consumables.
53. Backend `PlanCalculator` — единственный автор результата: `algorithm_version=maintenance-v3`, `config_version=condition-wear-v1`, immutable ruleset/snapshot. Canonical input включает `as_of_date`, sorted history answers и latest applicable condition observations. UI preferences полностью исключены; одинаковый input/date переиспользуется.
54. PATCH релевантного calculator input инвалидирует remote cache и загружает новый snapshot; старый snapshot может остаться в локальном кеше только для безопасного rollback/аудита и не показывается как актуальный. Одинаковый input может вернуть прежний snapshot ID либо идентичный content hash.
55. Active remote surface включает maintenance plan/timeline/consumables, `GET mileage-forecast`, `GET/POST condition-observations`, history answers, mileage и history. `GET/PUT plan-item-ui-preferences` помечены future contract и активных routes не имеют. POST condition observation и history создают новый v3 snapshot. PATCH/DELETE records остаются future.
56. `HistoryAnswerDto` хранит последнюю декларацию: `done_known|done_unknown|not_done|unknown|not_applicable`, nullable performed date/mileage и version. `done_known` требует хотя бы один baseline; прочие запрещают baselines. Один и тот же controller/repository используется full wizard и single-item flow из consumable side-sheet.
57. После успешного POST repository одной операцией записывает ответы, инвалидирует plan/timeline/consumables providers и загружает возвращённый `maintenance_plan_id`. Offline-предположение результата запрещено; retry сохраняет `Idempotency-Key`.
58. `ServiceRecordDto` и `HistoryAnswerDto` не объединяются: первый — persisted chronology, второй — latest declaration/prefill. Создание history answer не создаёт record; создание record обновляет declaration как часть серверной транзакции.
59. При `activeVehicle != null` application state не может деградировать в `noVehiclePreview`. Notifications показывает empty/list выбранной машины; Journal — records/real empty; Analytics — real empty без demo; Reminders — `featureNotReady`; AI — выбранную машину и `featureNotReady` без demo Q&A/add-car CTA. Это изменение не реализует AI backend.
60. Active-vehicle invariant применяется к routes, nested screens и modal surfaces и проверяется матрицей RU/EN: запрещены `addVehicleFirst`, «нет выбранного автомобиля», «после добавления автомобиля» и Example/demo content.
61. `PlanItemUiPreferencesRepository` и hide/collapse flow не входят в active MVP. Существующая server table/model/migration сохранена dormant/reversible; preference никогда не влияет на plan, comparator, order, warnings, notifications или hashes.
62. Expanded future card показывает `Произвёл`. Состояние single-expanded остаётся локальным ephemeral UI; сетевых запросов preferences и действий `Скрыть`/`Показать` нет.
63. Condition update из expanded consumable всегда POST-ит новую observation с `wear_percent`, date, optional mileage, `self|workshop`, optional note. `remaining_percent` read-only; install date отсутствует. После ответа repository атомарно обновляет condition history, plan, timeline и consumables.
64. Semantic color mapping централизован в theme extension/token layer: danger/red = critical/immediate/overdue/critical wear; warning/amber = attention/soon/unknown safety; success/green = current/confirmed; info/blue/neutral = editorial/source/category. View models несут machine semantics, не raw RGB; текст/tooltip/semantics обязательны.

## Последствия

### Положительные

- Единый предсказуемый стек уже соответствует зависимостям проекта.
- Критический guest-first flow и auth-flow можно тестировать независимо.
- Offline-поведение, миграции и синхронизация становятся явной частью архитектуры.
- Замена backend-провайдеров не требует изменения мобильной предметной логики.
- Feature-first ограничивает масштаб изменений и упрощает параллельную разработку.
- Изоляция AI по `vehicle_id` и `conversation_id` исключает визуальное и контекстное смешение тем при переключении машины.
- Журнал даёт единый пользовательский поток без слияния доменных моделей обслуживания и расходов.
- Типизированные состояния аналитики, расходников и AI assessment исключают правдоподобные, но неподтверждённые UI-выводы.
- Единая taxonomy timeline ограничивает визуальный шум одной главной эмблемой и двумя вторичными индикаторами.
- Projection/read-model подход позволяет добавить rail, два compact signals и side-sheet без новых таблиц и дублирования доменных данных.
- ARB/`gen_l10n` дают единый типобезопасный источник RU/EN UI и accessibility-текста без связи отображаемых строк с навигацией или данными.
- Стабильный locale mode и отдельный effective locale обеспечивают немедленное переключение с предсказуемым русским fallback.
- Manual-first state machine позволяет поставить сквозной профиль без зависимости от внешнего provider и без ложного статуса декодирования.

### Отрицательные и риски

- Появляется код преобразования между API, Drift и domain/view моделями.
- Riverpod providers и go_router redirects требуют правил, иначе возможны скрытые зависимости и циклы.
- Offline-очередь требует идемпотентного API, обработки конфликтов и тестов восстановления.
- Drift schema migrations обязательны даже на раннем MVP; изменение таблиц без миграции запрещено.
- Feature-first не устраняет архитектурные границы автоматически, поэтому зависимости проверяются code review и тестами.
- Постоянный shell с пятью ветками, глобальной шапкой и модальными панелями требует явных правил восстановления состояния и accessibility.
- Объединённая хронология требует стабильной сортировки, пагинации и согласования optimistic updates из двух доменных источников.
- Два независимых scroll regions и modal side-sheet требуют проверки gesture conflicts, focus restoration и поведения при крупном системном шрифте.
- Для каждой новой пользовательской строки нужны синхронные RU/EN ARB entries и проверка переполнения/a11y.
- Требуются управляемый технический glossary и ручная верификация переводов maintenance content, чтобы локализация не меняла смысл источника.
- Дублирование условной валидации на клиенте и backend требует общих contract/table tests; клиентская проверка не заменяет серверную.

## Нерешённые детали локализации

- Точное имя и расположение поля активной локали в API contract наряду с `Accept-Language`; OpenAPI изменяется отдельной задачей.
- Владелец и процесс утверждения RU/EN glossary для проверенного maintenance catalog и технических цитат.
- Очерёдность внедрения locale-aware formatter на ещё не реализованных экранах; архитектурное правило зафиксировано, объём следующего этапа определяется отдельно.

## Отклонённые варианты

- **Provider/BLoC вместо Riverpod:** работоспособны, но не дают преимуществ, оправдывающих второй state-management подход при уже подключённом Riverpod.
- **Navigator API вручную вместо go_router:** увеличивает объём собственной логики deep links и guards.
- **Глобальные технические слои вместо feature-first:** усиливают связанность экранов одного сценария с общими папками и затрудняют вертикальную поставку.
- **`http` без Dio:** потребовал бы вручную собирать interceptors, refresh, cancellation и единый error pipeline.
- **SharedPreferences/непосредственный SQLite вместо Drift:** недостаточны для реляционной истории, транзакционной очереди, типобезопасных запросов и миграций.
