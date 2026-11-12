Uri? whatsappContactUri(String contact) {
  if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(contact.trim())) return null;
  final number = contact.replaceAll(RegExp(r'[^0-9]'), '');
  if (number.length < 7 || number.length > 15) return null;
  return Uri.https('wa.me', '/$number');
}
