import 'dart:math';

final _random = Random();

/// A short unique-enough id for a single-user, on-device app
/// (timestamp + a few random characters, so collisions aren't a concern).
String generateId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _random.nextInt(1 << 32).toRadixString(36);
  return '$time$rand';
}
