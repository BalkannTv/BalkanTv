import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balkan_connect/ad_payment.dart';
import 'package:balkan_connect/create_paid_ad_page.dart';
import 'package:balkan_connect/report_listing_page.dart';
import 'package:balkan_connect/balkan_splash.dart';

class AdFixture extends http.BaseClient {
  final requests = <String>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url.path);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'stripe_payment_link': ''}))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  test('Advertisement URLs and Stripe links reject insecure and lookalike destinations', () {
    expect(validAdUrl('https://example.com/banner.png'), isTrue);
    expect(validAdUrl('http://example.com/banner.png'), isFalse);
    expect(validAdUrl('javascript:alert(1)'), isFalse);
    expect(validAdUrl('https://user:password@example.com'), isFalse);
    expect(validStripeLink('https://buy.stripe.com/test_123abc'), isTrue);
    expect(validStripeLink('https://buy.stripe.com.evil.example/pay'), isFalse);
    expect(
      validStripeLink('https://buy.stripe.com/abc?redirect=elsewhere'),
      isFalse,
    );
  });
  testWidgets('Report requires an explanation before login or submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportListingPage(
          listingId: 'test',
          listingTitle: 'Test listing',
        ),
      ),
    );
    await tester.tap(find.text('Send report / Испрати пријава'));
    await tester.pump();
    expect(
      find.text('Please describe the problem in at least 20 characters.'),
      findsOneWidget,
    );
    expect(find.byType(ReportListingPage), findsOneWidget);
  });
  testWidgets(
    'Client advertisement form rejects insecure URLs and cannot mark itself paid',
    (tester) async {
      final fixture = AdFixture();
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(
        () => Supabase.initialize(
          url: 'https://fixture.example',
          publishableKey: 'test',
          httpClient: fixture,
          authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
            detectSessionInUri: false,
          ),
        ),
      );
      addTearDown(() => tester.runAsync(() => Supabase.instance.dispose()));
      await tester.pumpWidget(const MaterialApp(home: CreatePaidAdPage()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'My business');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'http://example.com/banner.png',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'javascript:alert(1)',
      );
      await tester.scrollUntilVisible(
        find.text('Submit advertisement'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Submit advertisement'));
      await tester.pump();
      expect(find.text('Enter a valid HTTPS image URL'), findsOneWidget);
      expect(find.text('Enter a valid HTTPS website URL'), findsOneWidget);
      expect(fixture.requests.where((p) => p.contains('/rpc/')), isEmpty);
      expect(find.text('Confirm Payment'), findsNothing);
    },
  );
  testWidgets('Desktop splash image is constrained', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: BalkanSplash(child: Text('Ready'))),
    );
    final size = tester.getSize(find.byType(Image));
    expect(size.width, lessThanOrEqualTo(420));
    expect(size.height, lessThanOrEqualTo(600));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Ready'), findsOneWidget);
  });
}
