# Архитектура AutoDoctor MVP

## Компоненты

```text
Flutter Android/iOS
        │ HTTPS JSON
        ▼
Laravel Cloud, Frankfurt
  ├── Laravel API
  ├── Filament Admin
  ├── Managed PostgreSQL
  ├── Managed Queues
  └── Scheduler
        ├── VIN provider adapter
        └── AI provider adapter
```

## Принципы

- Сервер является источником истины после регистрации.
- До регистрации данные принадлежат анонимной сессии и мигрируют в аккаунт атомарно.
- План ТО рассчитывается детерминированно, а не языковой моделью.
- AI получает только обезличенный структурированный контекст.
- VIN-провайдер и AI-провайдер заменяются через серверные адаптеры.
- Системные правила версионируются и проходят публикационный workflow.
- Пользовательские напоминания не превращаются в системные автоматически.

## Среды

- `local` — SQLite и локальные тесты;
- `development` / пилот — текущее приложение Laravel Cloud Frankfurt, GitHub `AlexKhvostov/autodoctor`, каталог `apps/api`, ветка `main`;
- `production` — отдельная среда и отдельная БД **после** приёмки пилота. Пока не путать с ярлыком `production` в Laravel Cloud, если на том же приложении висит `api-dev`.

## Домены (зафиксировано 2026-08-26)

| Адрес | Назначение | Статус |
|--------|------------|--------|
| `https://autodoctor.by/` | Сайт / лендинг. SSL включён. | Готово (Hostland) |
| `https://api-dev.autodoctor.by` | API пилота. Привязан к приложению `autodoctor` в Laravel Cloud. | Живой Cloud-домен |
| `https://api.autodoctor.by` | Боевой API после отдельной production-среды. | Запланирован, не смешивать с пилотом |

Аккаунт Laravel Cloud: [cloud.laravel.com/aleksei-xvostov](https://cloud.laravel.com/aleksei-xvostov). Почта и DNS корня — Hostland.

Клиент (APK) ходит на `{host}/api/v1`, не на корень сайта `autodoctor.by`.

Чеклист пилота в Cloud: [laravel-cloud-pilot.md](laravel-cloud-pilot.md).

## Решения

- Клиент: Flutter + Dart.
- Backend: Laravel.
- Админка: Filament.
- Серверная БД: PostgreSQL.
- Размещение: Laravel Cloud Starter, EU Central Frankfurt.
- Домен и почта: Hostland.
- Firebase проект `autodoctor-by` (Spark): Analytics и Remote Config. Android package `by.autodoctor.autodoctor`.
- Адрес API для пилотного APK: Remote Config ключ `api_base_url`; ручной выбор в **Ещё → Разработка → Сервер API** сильнее RC.

## Документы проектирования

- [UX-flow и карта экранов](ux-flow.md)
- [Модель данных MVP](data-model.md)
- [ADR-001: мобильная архитектура Flutter](adr/001-mobile-architecture.md)
