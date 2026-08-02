import 'payment.dart';
import 'photo_paths.dart';

const dressTypes = [
  'Gown',
  'Skirt',
  'Blouse / Top',
  'Trousers',
  'Traditional Wear',
  'Suit',
  'Other',
];

/// The production stages, always in this fixed order.
const orderStatuses = [
  'Getting Fabrics',
  'Cutting',
  'Finishing',
  'Ready for Pickup',
  'Delivered',
];

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.dressType,
    required this.fabricDescription,
    required this.fabricPhotoPaths,
    required this.price,
    required this.materialsCost,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.payments,
  });

  final String id;
  final String customerId;
  final String dressType;
  final String fabricDescription;
  final List<String> fabricPhotoPaths;
  final double price;

  /// What the fabric/materials for this order cost Tessy — separate from
  /// [price], which is what the customer pays. Null means not recorded.
  final double? materialsCost;

  /// ISO yyyy-MM-dd, or null if no due date was set.
  final String? dueDate;
  final String status;
  final DateTime createdAt;
  final List<Payment> payments;

  double get amountPaid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => price - amountPaid;
  double get profit => price - (materialsCost ?? 0);

  Order copyWith({
    String? dressType,
    String? fabricDescription,
    List<String>? fabricPhotoPaths,
    double? price,
    double? materialsCost,
    String? dueDate,
    bool clearDueDate = false,
    String? status,
    List<Payment>? payments,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      dressType: dressType ?? this.dressType,
      fabricDescription: fabricDescription ?? this.fabricDescription,
      fabricPhotoPaths: fabricPhotoPaths ?? this.fabricPhotoPaths,
      price: price ?? this.price,
      materialsCost: materialsCost ?? this.materialsCost,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      createdAt: createdAt,
      payments: payments ?? this.payments,
    );
  }

  /// Columns only — payments live in their own table.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'dressType': dressType,
      'fabricDescription': fabricDescription,
      'fabricPhotoPaths': encodePhotoPaths(fabricPhotoPaths),
      'price': price,
      'materialsCost': materialsCost,
      'dueDate': dueDate,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, Object?> map, {List<Payment> payments = const []}) {
    return Order(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      dressType: map['dressType'] as String,
      fabricDescription: map['fabricDescription'] as String? ?? '',
      fabricPhotoPaths: decodePhotoPaths(map['fabricPhotoPaths']),
      price: (map['price'] as num).toDouble(),
      materialsCost: (map['materialsCost'] as num?)?.toDouble(),
      dueDate: map['dueDate'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      payments: payments,
    );
  }
}
