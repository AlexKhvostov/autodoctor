# Laravel Cloud: пилот API в интернете

Приложение уже висит на `https://api-dev.autodoctor.by`. Каталог деплоя: `apps/api`, ветка `main`, аккаунт [aleksei-xvostov](https://cloud.laravel.com/aleksei-xvostov).

Не создавайте второе приложение Cloud. Сайт `https://autodoctor.by/` — не API.

## Что уже работает (проверка 2026-08-26)

- `GET /api/v1/health` → `ok`
- анонимная сессия с `guest_profile_id`
- согласия, профиль агента, пустой гараж
- админка `/admin` открывается

## Что ещё сломано без действий в Cloud

1. Добавление машины отвечает `PLAN_PREPARING`: в PostgreSQL нет опубликованного регламента `by-pilot-baseline-2` (13 правил).
2. Вход Google отвечает `GOOGLE_AUTH_NOT_CONFIGURED`: нет `GOOGLE_CLIENT_ID` в переменных окружения Cloud.
3. AI не заговорит без `AI_ABACUS_API_KEY` или `AI_DEEPSEEK_API_KEY`.

## Команда в Laravel Cloud (один раз после деплоя)

В консоли приложения → Commands:

```bash
php artisan autodoctor:prepare-pilot
```

Она применяет миграции и сиды ТО + AI. Полный `DatabaseSeeder` не запускайте: он создаёт тестовых пользователей с паролем `password`.

На деплое оставьте `php artisan migrate --force`.

## Переменные окружения Cloud

Скопируйте значения из локального `apps/api/.env`, в git их нет.

Обязательно:

- `APP_KEY`
- `APP_URL=https://api-dev.autodoctor.by`
- `APP_ENV=production`
- `APP_DEBUG=false`
- `VIN_HASH_KEY`
- PostgreSQL — обычно Cloud подставляет сам
- `GOOGLE_CLIENT_ID` — тот же Web Client ID, что в APK (`GOOGLE_SERVER_CLIENT_ID`)
- `GOOGLE_ANDROID_CLIENT_ID` — Android OAuth client
- `AI_ABACUS_API_KEY` и/или `AI_DEEPSEEK_API_KEY`

Очереди: включите worker, `QUEUE_CONNECTION` как в Cloud (обычно database или redis).

После смены env Cloud перезапускает приложение. Затем проверьте с телефона APK `0.1.0+21` (адрес из Firebase Remote Config).
