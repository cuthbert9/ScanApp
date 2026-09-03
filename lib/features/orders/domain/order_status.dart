/// Where a delivery order has got to on the dock.
///
/// The order of the values is the order work flows in, which is also the order
/// the queue sorts by.
enum OrderStatus {
  /// Released by Warehouse Management and staged, waiting its turn.
  queued('Queued'),

  /// Currently being loaded onto a truck.
  loading('Loading'),

  /// Fully loaded and signed off.
  loaded('Loaded'),

  /// Staged, but no vehicle has been assigned to it yet.
  noTruck('No truck'),

  /// Stopped for a reason that needs a supervisor — a discrepancy, a recall.
  held('Held');

  const OrderStatus(this.label);

  /// Operator-facing label. Rendered upper-case by the badge.
  final String label;

  /// Whether this order is the one currently being worked.
  bool get isActive => this == OrderStatus.loading;

  /// Whether the order cannot progress without something changing outside the
  /// app — a truck arriving, a supervisor releasing a hold.
  bool get isBlocked => this == OrderStatus.noTruck || this == OrderStatus.held;
}
