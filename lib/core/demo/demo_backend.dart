/// Result of a routed demo request: HTTP status + JSON-encodable body.
typedef DemoResult = ({int status, Object? body});

/// In-process fake LubeLogger server for demo mode (see [DemoConfig]).
///
/// Serves a fabricated dataset shaped like the real `/api` contract under the
/// culture-invariant header (typed JSON: real bools/numbers, ISO dates, .NET
/// enum names). State is mutable — every add/update/delete mutates it so the
/// app feels alive; aggregates (`/vehicle/info`, reminder urgency) are computed
/// from the current records so the dashboard always agrees with the tabs.
///
/// One instance per process (the UI isolate and the reminder background isolate
/// each get their own, freshly seeded — both produce the same shape).
class DemoBackend {
  DemoBackend._() {
    _seed();
  }

  static final DemoBackend instance = DemoBackend._();

  /// Monotonic id source for created records. Starts above the fixed seed ids.
  int _nextId = 1000;
  int _newId() => ++_nextId;

  final List<Map<String, dynamic>> _vehicles = [];

  // Per-type records, each keyed by vehicleId. The endpoint segment selects the
  // collection (see [_collectionFor]); reads/writes all funnel through it.
  final Map<int, List<Map<String, dynamic>>> _gas = {};
  final Map<int, List<Map<String, dynamic>>> _odometer = {};
  final Map<int, List<Map<String, dynamic>>> _service = {};
  final Map<int, List<Map<String, dynamic>>> _repair = {};
  final Map<int, List<Map<String, dynamic>>> _upgrade = {};
  final Map<int, List<Map<String, dynamic>>> _tax = {};
  final Map<int, List<Map<String, dynamic>>> _supply = {};
  final Map<int, List<Map<String, dynamic>>> _plan = {};
  final Map<int, List<Map<String, dynamic>>> _reminders = {};
  final Map<int, List<Map<String, dynamic>>> _notes = {};
  final Map<int, List<Map<String, dynamic>>> _equipment = {};

  Map<int, List<Map<String, dynamic>>>? _collectionFor(String segment) =>
      switch (segment) {
        'gasrecords' => _gas,
        'odometerrecords' => _odometer,
        'servicerecords' => _service,
        'repairrecords' => _repair,
        'upgraderecords' => _upgrade,
        'taxrecords' => _tax,
        'supplyrecords' => _supply,
        'planrecords' => _plan,
        'reminders' => _reminders,
        'notes' => _notes,
        'equipmentrecords' => _equipment,
        _ => null,
      };

  // ── Routing ───────────────────────────────────────────────────────────────

  /// Handle one request. [rawBody] is the already-JSON-decoded Dio payload
  /// (map/list/null); FormData uploads are answered by the adapter, not here.
  DemoResult handle(String method, Uri uri, Object? rawBody) {
    final path = uri.path;
    if (!path.startsWith('/api')) return _notFound();
    final seg = path
        .substring('/api'.length)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final q = uri.queryParameters;
    final body =
        rawBody is Map<String, dynamic> ? rawBody : const <String, dynamic>{};
    try {
      return _route(method, seg, q, body) ?? _fallback(method);
    } on Object {
      return (status: 500, body: {'message': 'demo backend error'});
    }
  }

  DemoResult _ok(Object? body) => (status: 200, body: body);
  DemoResult _notFound() => (status: 404, body: {'message': 'Not Found'});

  /// Unknown writes still "succeed" (so a not-yet-modelled action never breaks
  /// the demo); unknown reads 404.
  DemoResult _fallback(String method) => method == 'GET'
      ? _notFound()
      : _ok({'success': true, 'message': ''});

  DemoResult? _route(
    String m,
    List<String> s,
    Map<String, String> q,
    Map<String, dynamic> body,
  ) {
    bool at(int i, String name) => i < s.length && s[i] == name;

    if (s.isEmpty) return _notFound();
    switch (s[0]) {
      case 'whoami':
        return _ok(_whoami);
      case 'info':
        return _ok(_info);
      case 'extrafields':
        return _ok(_extraFieldTemplates);
      case 'version':
        return _ok(_version);
      case 'makebackup':
        return _ok('/demo/backups/lubelogger_demo_backup.zip');
      case 'documents':
        // Non-FormData fallback; real uploads are handled by the adapter.
        if (at(1, 'upload')) return _ok(const <Object>[]);
        return _ok(const <Object>[]);
      case 'vehicles':
        if (s.length == 1 && m == 'GET') return _ok(_vehicles);
        if (at(1, 'add') && m == 'POST') return _addVehicle(body);
        if (at(1, 'update') && m == 'PUT') return _updateVehicle(body);
        if (at(1, 'delete') && m == 'DELETE') {
          return _deleteVehicle(_int(q['id']));
        }
        return null;
      case 'vehicle':
        if (s.length < 2) return _notFound();
        final sub = s[1];
        if (sub == 'info' && m == 'GET') {
          // No vehicleId means the whole garage, as on the server — that form
          // is the single request the garage screen makes.
          final id = _int(q['vehicleId']);
          return _ok(id == 0
              ? [for (final v in _vehicles) _vehicleInfo(_int(v['id']))]
              : [_vehicleInfo(id)]);
        }
        final coll = _collectionFor(sub);
        if (coll == null) return _notFound();
        final action = s.length > 2 ? s[2] : null;
        if (action == null && m == 'GET') {
          return _ok(coll[_int(q['vehicleId'])] ?? const <Object>[]);
        }
        if (action == 'add' && m == 'POST') {
          return _addRecord(sub, coll, _int(q['vehicleId']), body);
        }
        if (action == 'update' && m == 'PUT') {
          return _updateRecord(sub, coll, body);
        }
        if (action == 'delete' && m == 'DELETE') {
          return _deleteRecord(coll, _int(q['id']));
        }
        return null;
      default:
        return _notFound();
    }
  }

  // ── Record writes ──────────────────────────────────────────────────────────

  /// The one write the real API refuses (`PlanController.cs:150`). Mirrored so
  /// demo mode can't quietly accept what a live server would reject.
  DemoResult? _rejectDonePlan(String sub, Map<String, dynamic> body) =>
      (sub == 'planrecords' && body['progress'] == 'Done')
          ? (
              status: 400,
              body: {
                'success': false,
                'message':
                    'Input object invalid, Progress cannot be set to Done.',
              },
            )
          : null;

  DemoResult _addRecord(
    String sub,
    Map<int, List<Map<String, dynamic>>> coll,
    int vehicleId,
    Map<String, dynamic> body,
  ) {
    final rejected = _rejectDonePlan(sub, body);
    if (rejected != null) return rejected;
    final rec = <String, dynamic>{...body, 'id': _newId()};
    _fillDerivedFields(sub, vehicleId, rec, existing: null);
    (coll[vehicleId] ??= []).add(rec);
    return _ok({
      'success': true,
      'message': '',
      'additionalData': {'recordId': rec['id']},
    });
  }

  DemoResult _updateRecord(
    String sub,
    Map<int, List<Map<String, dynamic>>> coll,
    Map<String, dynamic> body,
  ) {
    final rejected = _rejectDonePlan(sub, body);
    if (rejected != null) return rejected;
    final id = _int(body['id']);
    for (final entry in coll.entries) {
      final idx = entry.value.indexWhere((r) => _int(r['id']) == id);
      if (idx < 0) continue;
      final rec = <String, dynamic>{...body, 'id': id};
      _fillDerivedFields(sub, entry.key, rec, existing: entry.value[idx]);
      entry.value[idx] = rec;
      break;
    }
    return _ok({'success': true, 'message': ''});
  }

  DemoResult _deleteRecord(
    Map<int, List<Map<String, dynamic>>> coll,
    int id,
  ) {
    for (final list in coll.values) {
      list.removeWhere((r) => _int(r['id']) == id);
    }
    return _ok({'success': true, 'message': ''});
  }

  /// Fills fields the write model omits but reads expect: reminder [urgency]
  /// (computed server-side), a plan's `dateCreated`, and an odometer record's
  /// `initialOdometer` (previous reading).
  void _fillDerivedFields(
    String sub,
    int vehicleId,
    Map<String, dynamic> rec, {
    Map<String, dynamic>? existing,
  }) {
    switch (sub) {
      case 'reminders':
        rec['urgency'] = _computeUrgency(vehicleId, rec);
      case 'planrecords':
        rec['dateCreated'] =
            existing?['dateCreated'] ?? _isoDate(DateTime.now());
      case 'odometerrecords':
        rec.putIfAbsent('initialOdometer', () => _lastOdometer(vehicleId));
    }
  }

  // ── Vehicle writes ─────────────────────────────────────────────────────────

  DemoResult _addVehicle(Map<String, dynamic> body) {
    final id = _newId();
    _vehicles.add(_vehicleFromWrite(body, id));
    return _ok({
      'success': true,
      'message': '',
      'additionalData': {'vehicleId': id},
    });
  }

  /// Mirrors the server's cascading delete: drop the vehicle and every record
  /// collection keyed by its id.
  DemoResult _deleteVehicle(int id) {
    _vehicles.removeWhere((v) => _int(v['id']) == id);
    for (final coll in [
      _gas,
      _odometer,
      _service,
      _repair,
      _upgrade,
      _tax,
      _supply,
      _plan,
      _reminders,
      _notes,
      _equipment,
    ]) {
      coll.remove(id);
    }
    return _ok({'success': true, 'message': ''});
  }

  DemoResult _updateVehicle(Map<String, dynamic> body) {
    final id = _int(body['id']);
    final idx = _vehicles.indexWhere((v) => _int(v['id']) == id);
    if (idx >= 0) {
      final existingImage = _vehicles[idx]['imageLocation'];
      _vehicles[idx] = _vehicleFromWrite(body, id)
        ..['imageLocation'] = existingImage;
    }
    return _ok({'success': true, 'message': ''});
  }

  /// Translate the string-typed `VehicleImportModel` write body into the typed
  /// read shape ([Vehicle]) the app parses back.
  Map<String, dynamic> _vehicleFromWrite(Map<String, dynamic> body, int id) {
    final fuelType = (body['fuelType'] as String?) ?? 'Gasoline';
    final tags = ((body['tags'] as String?) ?? '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    return {
      'id': id,
      'year': _int(body['year']),
      'make': (body['make'] as String?) ?? '',
      'model': (body['model'] as String?) ?? '',
      'licensePlate': (body['licensePlate'] as String?) ?? '',
      'imageLocation': '',
      'tags': tags,
      'isElectric': fuelType == 'Electric',
      'isDiesel': fuelType == 'Diesel',
      'useHours': _bool(body['useEngineHours']),
      'odometerOptional': _bool(body['odometerOptional']),
      'vehicleIdentifier': (body['identifier'] as String?) ?? 'LicensePlate',
      'extraFields': body['extraFields'] ?? const <Object>[],
    };
  }

  // ── Aggregates ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _vehicleInfo(int vehicleId) {
    final vehicle = _vehicles.firstWhere(
      (v) => _int(v['id']) == vehicleId,
      orElse: () => _vehicles.isNotEmpty ? _vehicles.first : <String, dynamic>{},
    );
    var veryUrgent = 0, urgent = 0, notUrgent = 0, pastDue = 0;
    for (final r in _reminders[vehicleId] ?? const []) {
      switch ((r['urgency'] as String?)?.toLowerCase()) {
        case 'pastdue':
          pastDue++;
        case 'veryurgent':
          veryUrgent++;
        case 'urgent':
          urgent++;
        default:
          notUrgent++;
      }
    }
    return {
      'vehicleData': vehicle,
      'lastReportedOdometer': _lastOdometer(vehicleId),
      'serviceRecordCost': _sumCost(_service[vehicleId]),
      'repairRecordCost': _sumCost(_repair[vehicleId]),
      'upgradeRecordCost': _sumCost(_upgrade[vehicleId]),
      'taxRecordCost': _sumCost(_tax[vehicleId]),
      'gasRecordCost': _sumCost(_gas[vehicleId]),
      'veryUrgentReminderCount': veryUrgent,
      'urgentReminderCount': urgent,
      'notUrgentReminderCount': notUrgent,
      'pastDueReminderCount': pastDue,
    };
  }

  double _sumCost(List<Map<String, dynamic>>? records) => [
        for (final r in records ?? const []) _double(r['cost']),
      ].fold(0.0, (a, b) => a + b);

  /// Highest odometer across every reading source for a vehicle — mirrors the
  /// server's "last reported odometer".
  double _lastOdometer(int vehicleId) {
    var best = 0.0;
    for (final coll in [
      _gas[vehicleId],
      _odometer[vehicleId],
      _service[vehicleId],
      _repair[vehicleId],
      _upgrade[vehicleId],
    ]) {
      for (final r in coll ?? const []) {
        final o = _double(r['odometer']);
        if (o > best) best = o;
      }
    }
    return best;
  }

  /// Reminder urgency, computed from time/distance to due (approximates the
  /// server's configurable thresholds). Returns a .NET enum name.
  String _computeUrgency(int vehicleId, Map<String, dynamic> rec) {
    final metric = (rec['metric'] as String?)?.toLowerCase() ?? 'date';
    final now = DateTime.now();
    var rank = 0; // 0 NotUrgent · 1 Urgent · 2 VeryUrgent · 3 PastDue
    int worse(int a, int b) => a > b ? a : b;

    if (metric != 'odometer') {
      final due = rec['dueDate'] is String
          ? DateTime.tryParse(rec['dueDate'] as String)
          : null;
      if (due != null) {
        final days = due.difference(now).inDays;
        rank = worse(
          rank,
          days < 0
              ? 3
              : days <= 7
                  ? 2
                  : days <= 30
                      ? 1
                      : 0,
        );
      }
    }
    if (metric != 'date') {
      final dueOdo = _double(rec['dueOdometer']);
      if (dueOdo > 0) {
        final dist = dueOdo - _lastOdometer(vehicleId);
        rank = worse(
          rank,
          dist < 0
              ? 3
              : dist <= 500
                  ? 2
                  : dist <= 2000
                      ? 1
                      : 0,
        );
      }
    }
    return switch (rank) {
      3 => 'PastDue',
      2 => 'VeryUrgent',
      1 => 'Urgent',
      _ => 'NotUrgent',
    };
  }

  // ── Static endpoints ───────────────────────────────────────────────────────

  Map<String, dynamic> get _whoami => {
        'username': 'demo',
        'emailAddress': 'demo@lubelogger.app',
        'isAdmin': true,
        'isRoot': true,
      };

  // 1.7.0: the fake backend implements the 1.7.0 vehicle-delete endpoint, so it
  // reports that version to keep the delete action enabled in the demo.
  /// `/api/extrafields` shape: `fieldType` as the .NET enum **name** and only
  /// the types that have fields configured, exactly as the real server answers.
  List<Map<String, dynamic>> get _extraFieldTemplates => [
        {
          'recordType': 'ServiceRecord',
          'extraFields': [
            {'name': 'Workshop', 'isRequired': true, 'fieldType': 'Text'},
            {'name': 'Warranty until', 'isRequired': false, 'fieldType': 'Date'},
          ],
        },
        {
          'recordType': 'GasRecord',
          'extraFields': [
            {'name': 'Station', 'isRequired': false, 'fieldType': 'Text'},
          ],
        },
      ];

  Map<String, dynamic> get _info => {
        'currentVersion': '1.7.0',
        'locale': 'en-US',
        'currencySymbol': r'$',
        'decimalSeparator': '.',
        'dateFormat': 'M/d/yyyy',
      };

  Map<String, dynamic> get _version => {
        'currentVersion': '1.7.0',
        'latestVersion': '1.7.0',
      };

  // ── Seed dataset ───────────────────────────────────────────────────────────

  void _seed() {
    final now = DateTime.now();
    String ago(int days) => _isoDate(now.subtract(Duration(days: days)));
    String ahead(int days) => _isoDate(now.add(Duration(days: days)));

    _vehicles.addAll([
      {
        'id': 1,
        'year': 2019,
        'make': 'Toyota',
        'model': 'Corolla',
        'licensePlate': 'DEMO-101',
        'imageLocation': 'assets/demo/car_photo1.jpg',
        'tags': ['daily'],
        'isElectric': false,
        'isDiesel': false,
        'useHours': false,
        'odometerOptional': false,
        'vehicleIdentifier': 'LicensePlate',
        'extraFields': const <Object>[],
      },
      {
        'id': 2,
        'year': 2017,
        'make': 'Volkswagen',
        'model': 'Passat',
        'licensePlate': 'DEMO-202',
        'imageLocation': 'assets/demo/car_photo2.webp',
        'tags': ['family'],
        'isElectric': false,
        'isDiesel': true,
        'useHours': false,
        'odometerOptional': false,
        'vehicleIdentifier': 'LicensePlate',
        'extraFields': const <Object>[],
      },
      {
        'id': 3,
        'year': 2022,
        'make': 'Nissan',
        'model': 'Leaf',
        'licensePlate': 'DEMO-303',
        // No photo asset for this one; the garage card falls back to its
        // placeholder, which is worth showing off too.
        'imageLocation': '',
        'tags': ['electric'],
        'isElectric': true,
        'isDiesel': false,
        'useHours': false,
        'odometerOptional': false,
        'vehicleIdentifier': 'LicensePlate',
        'extraFields': const <Object>[],
      },
    ]);

    // Vehicle 1 — monthly fill-to-full refuels, odometer 60k → ~68k.
    _gas[1] = _fuelSeries(
      count: 9,
      startOdometer: 60000,
      stepPerFill: 830,
      litresPerFill: 41,
      costPerFill: 64,
      ago: ago,
    );
    // Vehicle 2 — diesel, thirstier tank, odometer 130k → ~142k.
    _gas[2] = _fuelSeries(
      count: 8,
      startOdometer: 130000,
      stepPerFill: 1500,
      litresPerFill: 55,
      costPerFill: 78,
      ago: ago,
    );

    // Vehicle 3 — electric, 40 kWh pack, odometer 24k → ~33k.
    // Roughly 165 km between charges on a 40 kWh pack, which works out near
    // 15 kWh/100 km — where a real Leaf sits, and now a number the tab and
    // dashboard put a kWh label on. The odometer reading below follows from it.
    _gas[3] = _chargeSeries(
      count: 9,
      startOdometer: 31650,
      stepPerCharge: 140,
      batteryKwh: 40,
      pricePerKwh: 0.42,
      ago: ago,
    );

    _odometer[1] = [
      _rec({'date': ago(6), 'odometer': 67650, 'initialOdometer': 66900}),
      _rec({'date': ago(95), 'odometer': 64200, 'initialOdometer': 63500}),
    ];
    _odometer[2] = [
      _rec({'date': ago(18), 'odometer': 141800, 'initialOdometer': 141000}),
    ];
    _odometer[3] = [
      _rec({'date': ago(11), 'odometer': 33080, 'initialOdometer': 32995}),
    ];

    _service[1] = [
      _rec({
        'date': ago(38),
        'odometer': 66800,
        'description': 'Oil & filter change',
        'cost': 58.0,
        'notes': 'Fully synthetic 5W-30.',
        // So the demo shows a card carrying both markers. A bundled asset, not
        // a `/documents/...` path: nothing here reaches a server, and the image
        // viewer discriminates on the `assets/` prefix the same way the garage
        // covers do.
        'files': [
          {
            'name': 'invoice.jpg',
            'location': 'assets/demo/car_photo1.jpg',
            'isPending': false,
          },
        ],
        // Records report `fieldType` as the integer, unlike the template above.
        'extraFields': [
          {
            'name': 'Workshop',
            'value': 'Demo Motors',
            'isRequired': true,
            'fieldType': 0,
          },
        ],
      }),
      _rec({
        'date': ago(160),
        'odometer': 63100,
        'description': 'Cabin air filter replacement',
        'cost': 24.0,
      }),
    ];
    _service[2] = [
      _rec({
        'date': ago(90),
        'odometer': 138400,
        'description': 'DSG transmission oil service',
        'cost': 210.0,
      }),
    ];
    _service[3] = [
      _rec({
        'date': ago(52),
        'odometer': 30100,
        'description': 'Brake fluid change',
        'cost': 70.0,
        'notes': 'Regenerative braking spares the pads, not the fluid.',
      }),
    ];

    _repair[1] = [
      _rec({
        'date': ago(72),
        'odometer': 65200,
        'description': 'Replace front brake pads & discs',
        'cost': 185.0,
      }),
    ];
    _repair[2] = [
      _rec({
        'date': ago(150),
        'odometer': 135600,
        'description': 'Replace glow plugs',
        'cost': 260.0,
      }),
    ];

    _upgrade[1] = [
      _rec({
        'date': ago(205),
        'odometer': 61200,
        'description': 'All-season tyres (set of 4)',
        'cost': 520.0,
      }),
    ];
    _upgrade[2] = [
      _rec({
        'date': ago(300),
        'odometer': 128900,
        'description': 'Tow bar installation',
        'cost': 340.0,
      }),
    ];

    // Tax records carry no odometer.
    _tax[1] = [
      _rec({'date': ago(58), 'description': 'Annual road tax', 'cost': 140.0}),
    ];
    _tax[2] = [
      _rec({'date': ago(30), 'description': 'Annual road tax', 'cost': 180.0}),
    ];
    _tax[3] = [
      _rec({'date': ago(75), 'description': 'Annual road tax', 'cost': 0.0}),
    ];

    _supply[1] = [
      _rec({
        'date': ago(38),
        'description': 'Engine oil 5W-30 (5 L)',
        'partNumber': 'OIL-5W30-5L',
        'partSupplier': 'AutoParts',
        'partQuantity': 1,
        'cost': 35.0,
      }),
      _rec({
        'date': ago(120),
        'description': 'Wiper blades (pair)',
        'partNumber': 'WB-24-19',
        'partSupplier': 'AutoParts',
        'partQuantity': 2,
        'cost': 18.0,
      }),
    ];
    _supply[2] = [
      _rec({
        'date': ago(90),
        'description': 'Diesel fuel filter',
        'partNumber': 'FF-2017',
        'partSupplier': 'DieselPro',
        'partQuantity': 1,
        'cost': 28.0,
      }),
    ];

    _plan[1] = [
      _rec({
        'dateCreated': ago(15),
        'description': 'Replace timing belt & water pump',
        'cost': 400.0,
        'type': 'ServiceRecord',
        'priority': 'Normal',
        'progress': 'InProgress',
        'notes': 'Due around 70,000 km.',
      }),
    ];
    _plan[2] = [
      _rec({
        'dateCreated': ago(40),
        'description': 'Refurbish alloy wheels',
        'cost': 300.0,
        'type': 'UpgradeRecord',
        'priority': 'Low',
        'progress': 'Backlog',
      }),
      // The API refuses to write a finished plan back, so the form opens this
      // one read-only. Seeded to keep that path reachable in demo mode.
      _rec({
        'dateCreated': ago(120),
        'description': 'Fit winter tyres',
        'cost': 480.0,
        'type': 'UpgradeRecord',
        'priority': 'Normal',
        'progress': 'Done',
        'notes': 'Completed on the planner board.',
      }),
    ];

    _reminders[1] = [
      _reminder(1, {
        'description': 'Oil change',
        'metric': 'Both',
        'dueDate': ago(4),
        'dueOdometer': 68500,
        'notes': 'Every 10,000 km or 12 months.',
      }),
      _reminder(1, {
        'description': 'Annual roadworthiness inspection',
        'metric': 'Date',
        'dueDate': ahead(21),
      }),
      _reminder(1, {
        'description': 'Rotate tyres',
        'metric': 'Odometer',
        'dueOdometer': 68000,
      }),
    ];
    _reminders[2] = [
      _reminder(2, {
        'description': 'MOT / inspection',
        'metric': 'Date',
        'dueDate': ahead(9),
      }),
      _reminder(2, {
        'description': 'Oil service',
        'metric': 'Odometer',
        'dueOdometer': 143000,
      }),
    ];

    _reminders[3] = [
      _reminder(3, {
        'description': 'Cabin filter replacement',
        'metric': 'Both',
        'dueDate': ahead(35),
        'dueOdometer': 35000,
      }),
      _reminder(3, {
        'description': 'Battery health check',
        'metric': 'Date',
        'dueDate': ahead(120),
      }),
    ];

    _notes[1] = [
      _rec({
        'description': 'Tyre pressure',
        'noteText': 'Front 2.4 bar / Rear 2.2 bar (cold).',
        'pinned': true,
      }),
    ];
    _notes[2] = [
      _rec({
        'description': 'AdBlue',
        'noteText': 'Top up AdBlue roughly every 8,000 km.',
        'pinned': false,
      }),
    ];
    _notes[3] = [
      _rec({
        'description': 'Charging',
        'noteText': 'Home wallbox 7.4 kW; keep the daily limit at 80%.',
        'pinned': true,
      }),
    ];

    _equipment[1] = [
      _rec({
        'description': 'Winter tyres',
        'isEquipped': true,
        'distanceTraveled': 3200,
      }),
      _rec({'description': 'Roof box', 'isEquipped': false}),
    ];
    _equipment[2] = [
      _rec({'description': 'Child seat', 'isEquipped': true}),
    ];
  }

  /// A refuel series with a monotonically rising odometer and monthly dates
  /// (newest last). Fill-to-full so [GasStats] can compute economy.
  List<Map<String, dynamic>> _fuelSeries({
    required int count,
    required int startOdometer,
    required int stepPerFill,
    required int litresPerFill,
    required int costPerFill,
    required String Function(int) ago,
  }) {
    final out = <Map<String, dynamic>>[];
    var odo = startOdometer;
    for (var i = count - 1; i >= 0; i--) {
      odo += stepPerFill + (i % 3) * 40;
      out.add(_rec({
        'date': ago(i * 30 + 5),
        'odometer': odo,
        'fuelConsumed': litresPerFill + (i % 4) - 1.5,
        'cost': costPerFill + (i % 5) * 2.5,
        'isFillToFull': true,
        'missedFuelUp': false,
      }));
    }
    return out;
  }

  /// Charging sessions for the demo EV. `fuelConsumed` is kWh and follows from
  /// the state-of-charge delta, so the pack size the server derives per record
  /// (`kWh / SoC delta`) lands on [batteryKwh] instead of a random number.
  List<Map<String, dynamic>> _chargeSeries({
    required int count,
    required int startOdometer,
    required int stepPerCharge,
    required double batteryKwh,
    required double pricePerKwh,
    required String Function(int) ago,
  }) {
    final out = <Map<String, dynamic>>[];
    var odo = startOdometer;
    for (var i = count - 1; i >= 0; i--) {
      odo += stepPerCharge + (i % 3) * 25;
      final startingSoc = 15 + (i % 4) * 5;
      final endingSoc = 80 + (i % 3) * 5;
      final kwh = batteryKwh * (endingSoc - startingSoc) / 100;
      out.add(_rec({
        'date': ago(i * 30 + 5),
        'odometer': odo,
        'fuelConsumed': _round2(kwh),
        'cost': _round2(kwh * pricePerKwh),
        'isFillToFull': true,
        'missedFuelUp': false,
        'startingSoc': startingSoc,
        'endingSoc': endingSoc,
      }));
    }
    return out;
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Seed a record map with a fresh id (fields the model reads that aren't
  /// supplied simply stay absent — the model tolerates that).
  Map<String, dynamic> _rec(Map<String, dynamic> fields) => {
        'id': _newId(),
        ...fields,
      };

  /// Seed a reminder, computing its urgency from the due date/odometer so the
  /// dashboard counts and the tab chips agree.
  Map<String, dynamic> _reminder(int vehicleId, Map<String, dynamic> fields) {
    final rec = _rec(fields);
    rec['urgency'] = _computeUrgency(vehicleId, rec);
    return rec;
  }

  // ── Coercions ──────────────────────────────────────────────────────────────

  static int _int(Object? v) => switch (v) {
        final int i => i,
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

  static double _double(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };

  static bool _bool(Object? v) => switch (v) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        _ => false,
      };

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
