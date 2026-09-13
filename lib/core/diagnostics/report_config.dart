import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:dio/dio.dart' show RequestOptions;

/// LubeLogger's half of the report contract, handed to `app_diagnostics` and
/// `app_report_client`. Asserted in `http_probe_test.dart` and
/// `log_redactor_test.dart`.

/// A quarter of an hour covers a reproduction here — every bug so far was one
/// form or one list — and 10 MB of JSONL is more than that ever writes.
const recordingLimit = Duration(minutes: 15);
const recordingSizeLimit = 10 * 1024 * 1024;

/// No trailing slash — both relay endpoints hang off this, and the prefix is
/// what picks the repository.
const String relayBaseUrl = 'https://app-relay.morganmlg.com/lubelogger';

/// Must equal the log's own `v`: the relay accepts a fixed window of schemas.
const int reportLogSchema = LogHeader.formatVersion;

final HttpProbeConfig lubeloggerHttpProbe = HttpProbeConfig(
  sampledPaths: _sampledPaths,
  maxClippedChars: 1500,
  // Every write goes out as strings the app formatted itself, so "the date came
  // back a day early" is answered by what left the phone.
  sampleRequests: true,
  fieldsOf: _requestIds,
  pathOf: loggablePath,
);

/// An allowlist: `whoami` answers with a person, and `documents/upload` echoes
/// the stored file name.
final RegExp _sampledPaths = RegExp(
  r'/api/(vehicles|vehicle/\w+|info|version)$',
);

/// Nearly every endpoint is scoped by `vehicleId`, and `?id=` is how a delete
/// names its target. Internal row ids name nobody.
Map<String, Object?> _requestIds(RequestOptions options) => {
  'vid': int.tryParse(options.uri.queryParameters['vehicleId'] ?? ''),
  'rid': int.tryParse(options.uri.queryParameters['id'] ?? ''),
};

LogRedactor lubeloggerRedactor({int maxStringLength = 2000}) => LogRedactor(
  maxStringLength: maxStringLength,
  ourKeys: lubeloggerOurKeys,
  // A LubeLogger instance is often shared by a household or a small fleet.
  secretKeyPatterns: [RegExp('email', caseSensitive: false)],
  freeTextKeys: _freeTextKeys,
  schemaKeys: _schemaKeys,
);

/// The app's own vocabulary, exempt from the scrub: a server called `garage`
/// or `vehicle` would otherwise eat control ids, routes and API paths.
final Map<String, RegExp> lubeloggerOurKeys = {
  'id': RegExp(r'^\w+(\.\w+)*$'),
  'surface': RegExp(r'^\w+(\.\w+)*$'),
  'to': RegExp(r'^/[\w\-/:]*$'),
  'from': RegExp(r'^/[\w\-/:]*$'),
  'path': RegExp(r'^/[\w\-/.]*$'),
  'role': RegExp(r'^[a-zA-Z]+$'),
  'kind': RegExp(r'^[a-zA-Z]+$'),
  'state': RegExp(r'^[a-zA-Z]+$'),
  'reason': RegExp(r'^[a-zA-Z]+$'),
  'method': RegExp(r'^[A-Z]+$'),
  'dir': RegExp(r'^[a-z]+$'),
  // Launcher shortcut names, straight out of `QuickActionsService`.
  'action': RegExp(r'^[a-z]+(_[a-z]+)*$'),
  // A Dart exception type, a dio error type, an `AppErrorCode`.
  'type': RegExp(r'^[A-Za-z_][A-Za-z0-9_<>, ]*$'),
  'via': RegExp(r'^[a-z]+$'),
  'ext': RegExp(r'^[a-z0-9]{1,8}$'),
  'limit': RegExp(r'^[a-z]+$'),
};

/// Exact lower-cased names: `partNumber` is the user's, `partQuantity` is a
/// number. `name`/`value` are an `extraFields` entry, where the user invents the
/// key as well as the content.
const Set<String> _freeTextKeys = {
  'description',
  'identifier',
  'imagelocation',
  'licenseplate',
  'location',
  'make',
  'model',
  'name',
  'notes',
  'notetext',
  'partnumber',
  'partsupplier',
  'tags',
  'value',
  'vehicleidentifier',
};

/// Server configuration a formatting report is read for, none of which survives
/// the shape rule: `MM/dd/yyyy` is not a date, `zł` is not a word.
///
/// `message` is `OperationResponse`'s, written by the server ("Access Denied",
/// "Invalid Record Id"). The probe measures an error body like a sample, and
/// without this every refusal would read `<str:13>`.
const Set<String> _schemaKeys = {
  'currencysymbol',
  'currentversion',
  'dateformat',
  'decimalseparator',
  'latestversion',
  'locale',
  'message',
};
