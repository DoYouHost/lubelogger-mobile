/// A record reduced to just its date and cost — the shared shape of service,
/// repair, upgrade, tax, and gas records for monthly expense aggregation.
class DatedCost {
  const DatedCost({required this.date, required this.cost});

  final DateTime? date;
  final double cost;
}
