# Laravel Cloud: пилот API в интернете

Приложение уже висит на `https://api-dev.autodoctor.by`. Каталог деплоя: `apps/api`, ветка `main`, аккаунт [aleksei-xvostov](https://cloud.laravel.com/aleksei-xvostov).

Не создавайте второе приложение Cloud. Сайт `https://autodoctor.by/` — не API.

## Что уже работает (проверка 2026-08-26)

- `GET /api/v1/health` → `ok`, в `checks` видны база и состояние AI (конфиг, enabled, ключ есть/нет, без самого секрета)
- анонимная сессия, гараж, план ТО после сида `MaintenanceV2Seeder`
- Google: ключи в **Custom environment variables** Cloud (не копировать весь `.env`)
- AI-чат отвечает, если в БД активна конфигурация (`AiConfigSeeder`) и задан `AI_ABACUS_API_KEY`
- админка Filament: [https://api-dev.autodoctor.by/admin](https://api-dev.autodoctor.by/admin)

## Админка (чаты, промпты, конфиг AI)

Локально и на пилоте после создания пользователя:

- Email: `admin@autodoctor.local`
- Password: `password` (тестовый; смените после входа)

Полный `php artisan db:seed` на Cloud **не запускайте**: он ещё создаёт `test@example.com`. Если входа нет, в Commands:

```bash
php artisan tinker --execute="App\Models\User::query()->updateOrCreate(['email'=>'admin@autodoctor.local'],['name'=>'AutoDoctor Admin','password'=>'password','is_admin'=>true]);"
```

Разделы: Assistant Threads, AI Prompt Versions, AI Config Versions.

## Команды в Laravel Cloud

После деплоя на каждом релизе достаточно:

```bash
php artisan migrate --force
```

Один раз для регламента ТО и AI-конфига (если чат пишет «временно отключён» — нет строки конфига в БД):

```bash
php artisan db:seed --class=MaintenanceV2Seeder --force
php artisan db:seed --class=AiConfigSeeder --force
```

Или одной командой: `php artisan autodoctor:prepare-pilot`.

Диагностика с телефона: **Ещё → Разработка** — статус API и кнопка «Проверить AI». Пилотный APK: `0.1.0+23`, адрес API из Firebase Remote Config.

## Переменные окружения Cloud

Скопируйте значения из локального `apps/api/.env`, в git их нет. Не перезаписывайте Injected `DB_*` / `APP_KEY` Cloud.

Нужны:

- `APP_URL=https://api-dev.autodoctor.by`
- `APP_ENV=production`
- `APP_DEBUG=false`
- `VIN_HASH_KEY`
- `GOOGLE_CLIENT_ID` — тот же Web Client ID, что в APK (`GOOGLE_SERVER_CLIENT_ID`)
- `GOOGLE_ANDROID_CLIENT_ID`
- `AI_ABACUS_API_KEY` и/или `AI_DEEPSEEK_API_KEY`

Очереди: включите worker, `QUEUE_CONNECTION` как в Cloud (обычно database или redis).
