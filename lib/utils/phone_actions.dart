import 'package:url_launcher/url_launcher.dart';

/// Converts a locally-typed phone number into the international-format
/// digits WhatsApp's wa.me links need (no leading '0', no '+', no spaces).
/// Assumes Ghana (+233) for numbers typed in the common local "0XXXXXXXXX"
/// form, since that's this app's target market — a number already given in
/// international form (with a '+') is left as whatever country it specifies.
String _digitsForWhatsApp(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) return digits.substring(1);
  if (digits.startsWith('0')) return '233${digits.substring(1)}';
  return digits;
}

Future<void> callPhone(String phone) async {
  await launchUrl(Uri(scheme: 'tel', path: phone));
}

Future<void> messageOnWhatsApp(String phone) async {
  final digits = _digitsForWhatsApp(phone);
  await launchUrl(
    Uri.parse('https://wa.me/$digits'),
    mode: LaunchMode.externalApplication,
  );
}
