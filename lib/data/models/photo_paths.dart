import 'dart:convert';

/// Shared by [Customer] and [Order] — encodes/decodes the JSON-array-of-
/// paths column both use to store more than one photo per record.
String encodePhotoPaths(List<String> paths) => jsonEncode(paths);

List<String> decodePhotoPaths(Object? raw) {
  if (raw == null) return const [];
  return (jsonDecode(raw as String) as List).cast<String>();
}
