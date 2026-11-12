import 'package:flutter_test/flutter_test.dart';
import 'package:balkan_connect/listing_contact.dart';

void main() {
  test('WhatsApp contact accepts international phone numbers without URL injection', () {
    expect(
      whatsappContactUri('+420 123 456 789').toString(),
      'https://wa.me/420123456789',
    );
    expect(whatsappContactUri('https://example.com/123456789'), isNull);
    expect(whatsappContactUri('123?text=hello'), isNull);
    expect(whatsappContactUri('12'), isNull);
    expect(whatsappContactUri(''), isNull);
  });
}
