/// One recorded value for a single measurement field at a point in time —
/// a new entry is added whenever that field's value changes, rather than
/// overwriting, so past values for a customer aren't lost.
class MeasurementHistoryEntry {
  const MeasurementHistoryEntry({
    required this.id,
    required this.customerId,
    required this.fieldKey,
    required this.value,
    required this.recordedAt,
  });

  final String id;
  final String customerId;
  final String fieldKey;
  final double value;
  final DateTime recordedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'fieldKey': fieldKey,
      'value': value,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory MeasurementHistoryEntry.fromMap(Map<String, Object?> map) {
    return MeasurementHistoryEntry(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      fieldKey: map['fieldKey'] as String,
      value: (map['value'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
    );
  }
}
