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

API health-check: `GET /api/v1/health`.
Filament Admin: `/admin`.

Laravel Cloud подключается к этому репозиторию с Application directory `apps/api`.

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
