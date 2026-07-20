/// LLM config via `--dart-define` (never commit real keys).
///
/// Example:
/// `puro flutter run --dart-define=DEEPSEEK_API_KEY=sk-...`
class AssistantLlmConfig {
  const AssistantLlmConfig._();

  static const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
  static const baseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );
  static const model = String.fromEnvironment(
    'DEEPSEEK_MODEL',
    defaultValue: 'deepseek-chat',
  );

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
