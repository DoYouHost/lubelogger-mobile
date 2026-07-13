/// A record reduced to just its date and cost — the shared shape of service,
/// repair, upgrade, tax, and gas records for monthly expense aggregation.
class DatedCost {
  const DatedCost({required this.date, required this.cost});

  factory DatedCost.fromJson(Map<String, dynamic> json) => DatedCost(
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        cost: switch (json['cost']) {
          final num n => n.toDouble(),
          final String s => double.tryParse(s) ?? 0,
          _ => 0,
        },
      );

  final DateTime? date;
  final double cost;
}
