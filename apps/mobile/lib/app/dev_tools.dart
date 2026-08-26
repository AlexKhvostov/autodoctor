/// Developer-only surfaces (API switch, UI kit). Hide in store builds:
/// `--dart-define=SHOW_DEV_MENU=false`.
const showDevMenu = bool.fromEnvironment('SHOW_DEV_MENU', defaultValue: true);
