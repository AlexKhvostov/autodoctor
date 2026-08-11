# Google Sign-In (клиентское приложение)

## Сервер (`apps/api/.env`)

```env
GOOGLE_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=
GOOGLE_ANDROID_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=
```

`id_token` с телефона должен иметь `aud`, совпадающий с одним из этих Client ID.

## Google Cloud Console

1. Создайте OAuth Client **Web application** — это `GOOGLE_CLIENT_ID` (server / web).
2. Создайте OAuth Client **Android** (package + SHA-1) — `GOOGLE_ANDROID_CLIENT_ID`.
3. Для iOS — `GOOGLE_IOS_CLIENT_ID`.

## Мобильное приложение

Сборка с web client id (нужен для `idToken`):

```powershell
cd apps/mobile
flutter pub get
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=ВАШ_WEB_CLIENT_ID
```

В приложении: аватар профиля → **Войти через Google**.

Гостевой профиль привязывается к аккаунту: заметки и диалоги не теряются.

## Админка

Диалоги: `/admin` → AI → **Dialogues**.
