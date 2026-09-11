/// Backend endpoint configuration, resolved at build time.
///
/// Override with `--dart-define=API_BASE_URL=...` for a staging/sandbox
/// server; the default is the production MSD ERP host.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.mag-erp.com/erp-api',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
