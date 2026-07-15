/// A file attached to a record — LubeLogger's `UploadedFiles`. Uploading via
/// `POST /api/documents/upload` returns these ([location] is a server path like
/// `/documents/<guid>.pdf`); they're then sent back in a record's `files` list
/// on add/update. All records except reminders carry files.
class Attachment {
  const Attachment({
    required this.name,
    required this.location,
    this.isPending = false,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        name: (json['name'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
        isPending: json['isPending'] == true,
      );

  /// Original file name, shown to the user.
  final String name;

  /// Server-relative storage path (e.g. `/documents/<guid>.pdf`).
  final String location;

  /// The server's transient flag for uploaded-but-unsaved files; always sent as
  /// false so an attached file is treated as permanent.
  final bool isPending;

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'isPending': isPending,
      };

  /// Parse a record's `files` array, skipping anything that isn't an object.
  static List<Attachment> listFrom(Object? raw) => raw is List
      ? [
          for (final e in raw)
            if (e is Map<String, dynamic>) Attachment.fromJson(e),
        ]
      : const [];
}
