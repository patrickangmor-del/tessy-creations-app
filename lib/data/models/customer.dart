/// A single measurement field shown in the customer form and detail view.
class MeasurementField {
  const MeasurementField(this.key, this.label);
  final String key;
  final String label;
}

const measurementFields = [
  MeasurementField('bust', 'Bust'),
  MeasurementField('waist', 'Waist'),
  MeasurementField('hip', 'Hip'),
  MeasurementField('shoulder', 'Shoulder'),
  MeasurementField('sleeveLength', 'Sleeve Length'),
  MeasurementField('fullLength', 'Full Length'),
];

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.notes,
    required this.photoPath,
    required this.bust,
    required this.waist,
    required this.hip,
    required this.shoulder,
    required this.sleeveLength,
    required this.fullLength,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String notes;
  final String? photoPath;
  final double? bust;
  final double? waist;
  final double? hip;
  final double? shoulder;
  final double? sleeveLength;
  final double? fullLength;
  final DateTime createdAt;

  /// Reads a measurement by [MeasurementField.key], for building the
  /// measurement grid without repeating a field-by-field switch everywhere.
  double? measurement(String key) {
    switch (key) {
      case 'bust':
        return bust;
      case 'waist':
        return waist;
      case 'hip':
        return hip;
      case 'shoulder':
        return shoulder;
      case 'sleeveLength':
        return sleeveLength;
      case 'fullLength':
        return fullLength;
      default:
        return null;
    }
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? notes,
    String? photoPath,
    bool clearPhoto = false,
    double? bust,
    double? waist,
    double? hip,
    double? shoulder,
    double? sleeveLength,
    double? fullLength,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      bust: bust ?? this.bust,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      shoulder: shoulder ?? this.shoulder,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      fullLength: fullLength ?? this.fullLength,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'photoPath': photoPath,
      'bust': bust,
      'waist': waist,
      'hip': hip,
      'shoulder': shoulder,
      'sleeveLength': sleeveLength,
      'fullLength': fullLength,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      bust: (map['bust'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      shoulder: (map['shoulder'] as num?)?.toDouble(),
      sleeveLength: (map['sleeveLength'] as num?)?.toDouble(),
      fullLength: (map['fullLength'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
