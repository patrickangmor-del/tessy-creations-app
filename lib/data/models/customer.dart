/// A single measurement field shown in the customer form and detail view.
class MeasurementField {
  const MeasurementField(this.key, this.label);
  final String key;
  final String label;
}

/// A group of related measurement fields, shown under a shared heading
/// (e.g. the three skirt-length variants). [title] is null for the leading
/// group of general fields, which sits directly under the screen's own
/// "Measurements" heading with no sub-heading of its own.
class MeasurementSection {
  const MeasurementSection(this.title, this.fields);
  final String? title;
  final List<MeasurementField> fields;
}

const measurementSections = [
  MeasurementSection(null, [
    MeasurementField('bust', 'Bust'),
    MeasurementField('waist', 'Waist'),
    MeasurementField('hips', 'Hips'),
    MeasurementField('shoulderToNipple', 'Shoulder to Nipple'),
    MeasurementField('shoulderToUnderBust', 'Shoulder to Under Bust'),
    MeasurementField('shoulderToWaist', 'Shoulder to Waist'),
    MeasurementField('acrossBack', 'Across Back'),
    MeasurementField('backWaistLength', 'Back Waist Length'),
    MeasurementField('aroundShoulder', 'Around Shoulder'),
  ]),
  MeasurementSection('Skirt / Slit Length', [
    MeasurementField('skirtLengthKnee', 'Knee Length'),
    MeasurementField('skirtLengthThreeQuarter', '3/4 Length'),
    MeasurementField('skirtLengthAnkle', 'Ankle Length'),
    MeasurementField('slitLength', 'Slit Length'),
  ]),
  MeasurementSection('Sleeve Length', [
    MeasurementField('sleeveLengthShort', 'Short'),
    MeasurementField('sleeveLengthElbow', 'Elbow'),
    MeasurementField('sleeveLengthLong', 'Long'),
  ]),
  MeasurementSection('Around Arm', [
    MeasurementField('aroundArmShort', 'Short'),
    MeasurementField('aroundArmElbow', 'Elbow'),
    MeasurementField('aroundArmWrist', 'Wrist'),
  ]),
];

/// Flat view of every field across all sections, in order — used wherever
/// the grouping doesn't matter (database columns, building a blank map).
final measurementFields = [
  for (final section in measurementSections) ...section.fields,
];

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.notes,
    required this.photoPath,
    required this.measurements,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String notes;
  final String? photoPath;

  /// Keyed by [MeasurementField.key]. Missing or null means not recorded.
  final Map<String, double?> measurements;
  final DateTime createdAt;

  double? measurement(String key) => measurements[key];

  Customer copyWith({
    String? name,
    String? phone,
    String? notes,
    String? photoPath,
    bool clearPhoto = false,
    Map<String, double?>? measurements,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      measurements: measurements ?? this.measurements,
      createdAt: createdAt,
    );
  }

  /// Each measurement is its own database column, so it's expanded out here
  /// rather than stored as the map itself.
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
    for (final field in measurementFields) {
      map[field.key] = measurements[field.key];
    }
    return map;
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      measurements: {
        for (final field in measurementFields) field.key: (map[field.key] as num?)?.toDouble(),
      },
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
