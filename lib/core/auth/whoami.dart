/// Identity of the authenticated caller, from `GET /api/whoami`.
class WhoAmI {
  const WhoAmI({
    required this.username,
    required this.emailAddress,
    required this.isAdmin,
    required this.isRoot,
  });

  factory WhoAmI.fromJson(Map<String, dynamic> json) => WhoAmI(
        username: (json['username'] as String?) ?? '',
        emailAddress: (json['emailAddress'] as String?) ?? '',
        // With the culture-invariant header these are real booleans; guard
        // against a stray locale string ("True") just in case.
        isAdmin: _asBool(json['isAdmin']),
        isRoot: _asBool(json['isRoot']),
      );

  final String username;
  final String emailAddress;
  final bool isAdmin;
  final bool isRoot;

  static bool _asBool(Object? v) =>
      v == true || v == 'true' || v == 'True';

  /// Best label for the caller: username, falling back to the email.
  String get displayName => username.isNotEmpty ? username : emailAddress;
}
