# AutoDoctor

AutoDoctor — мобильный помощник автовладельца с проверенным планом технического обслуживания, историей работ, пользовательскими напоминаниями и контекстным AI.

## Структура

```text
apps/
  api/      Laravel API и Filament Admin
  mobile/   Flutter-приложение Android/iOS
docs/       Архитектура и контракты
```

Каноническое техническое задание: [AutoDoctor_TZ_MVP.md](AutoDoctor_TZ_MVP.md).

Экспорт DOCX:

```bash
python -m pip install -r tools/requirements.txt
python tools/export_docx.py
```

Проектная документация:

- [UX-flow](docs/ux-flow.md);
- [OpenAPI 3.1](docs/openapi.yaml);
- [модель данных](docs/data-model.md);
- [ADR мобильной архитектуры](docs/adr/001-mobile-architecture.md).

Проверка OpenAPI:

```bash
python tools/validate_openapi.py
```

## Backend

Требования:

- PHP 8.3 или выше;
- Composer;
- PostgreSQL в Laravel Cloud;
- SQLite допускается только для локальной разработки и тестов.

```bash
cd apps/api
composer install
php artisan migrate
php artisan test
```

API health-check: `GET /api/v1/health` (в `checks` — база и AI).
Filament Admin пилота: [https://api-dev.autodoctor.by/admin](https://api-dev.autodoctor.by/admin)  
логин по умолчанию `admin@autodoctor.local` / `password` (см. [laravel-cloud-pilot.md](docs/laravel-cloud-pilot.md)).

Laravel Cloud подключается к этому репозиторию с Application directory `apps/api`.

Публичные адреса (на 2026-08-26):

- сайт: `https://autodoctor.by/` (SSL на Hostland);
- API пилота: `https://api-dev.autodoctor.by/api/v1`;
- аккаунт Cloud: [aleksei-xvostov](https://cloud.laravel.com/aleksei-xvostov).

## Mobile

Flutter SDK закреплён через Puro в `apps/mobile/.puro.json`.

```bash
cd apps/mobile
puro flutter pub get
puro flutter test
```

Для Android требуется завершить первоначальную установку Android SDK в Android Studio. Для подписанной iOS-сборки необходим macOS/Xcode или облачный CI.

## Безопасность

- Не добавлять `.env`, ключи API и пользовательские данные в Git.
- VIN, email и свободный текст не передаются аналитическим SDK.
- Production-секреты хранятся только в Laravel Cloud.
