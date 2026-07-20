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
- `development` — Laravel Cloud Frankfurt и development PostgreSQL;
- `production` — отдельные ресурсы Laravel Cloud после приёмки.

Планируемые домены:

- `api-dev.autodoctor.by`;
- `api.autodoctor.by`.

## Решения

- Клиент: Flutter + Dart.
- Backend: Laravel.
- Админка: Filament.
- Серверная БД: PostgreSQL.
- Размещение: Laravel Cloud Starter, EU Central Frankfurt.
- Домен и почта: Hostland.

## Документы проектирования

- [UX-flow и карта экранов](ux-flow.md)
- [Модель данных MVP](data-model.md)
- [ADR-001: мобильная архитектура Flutter](adr/001-mobile-architecture.md)
