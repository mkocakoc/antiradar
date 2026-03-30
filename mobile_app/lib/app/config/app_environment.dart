enum AppEnvironment {
  dev,
  staging,
  prod,
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.bffBaseUrl,
  });

  final AppEnvironment environment;
  final String bffBaseUrl;

  bool get isProd => environment == AppEnvironment.prod;

  static AppConfig fromDartDefines() {
    final rawEnv = const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = switch (rawEnv.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };

    final explicitBaseUrl = const String.fromEnvironment('BFF_BASE_URL', defaultValue: '');

    final fallbackBaseUrl = switch (environment) {
      AppEnvironment.dev => 'http://localhost:3000',
      AppEnvironment.staging => 'https://staging.api.antiradar.local',
      AppEnvironment.prod => 'https://api.antiradar.local',
    };

    return AppConfig(
      environment: environment,
      bffBaseUrl: explicitBaseUrl.isNotEmpty ? explicitBaseUrl : fallbackBaseUrl,
    );
  }
}
