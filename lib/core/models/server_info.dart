/// Server metadata from `GET /api/info`. Drives currency/number/date
/// formatting so the app matches the server's configured locale.
class ServerInfo {
  const ServerInfo({
    required this.currentVersion,
    required this.locale,
    required this.currencySymbol,
    required this.decimalSeparator,
    required this.dateFormat,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
        currentVersion: (json['currentVersion'] as String?) ?? '',
        locale: (json['locale'] as String?) ?? 'en-US',
        currencySymbol: (json['currencySymbol'] as String?) ?? r'$',
        decimalSeparator: (json['decimalSeparator'] as String?) ?? '.',
        dateFormat: (json['dateFormat'] as String?) ?? 'M/d/yyyy',
      );

  final String currentVersion;
  final String locale;
  final String currencySymbol;
  final String decimalSeparator;
  final String dateFormat;
}
