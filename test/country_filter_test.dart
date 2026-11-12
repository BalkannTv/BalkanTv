import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balkan_connect/country_selector.dart';
import 'package:balkan_connect/create_listing_page.dart';
import 'package:balkan_connect/listing_countries.dart';
import 'package:balkan_connect/published_listings.dart';

class FixtureClient extends http.BaseClient {
  final requests = <Uri>[];
  Completer<http.StreamedResponse>? nextResponse;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    if (request.url.path.endsWith('/paid_ads')) return response([]);
    if (nextResponse != null) {
      final pending = nextResponse!;
      nextResponse = null;
      return pending.future;
    }
    final country = request.url.queryParameters['or'] ?? '';
    final items = country.contains('eq.DE')
        ? [
            listing('German job', 'jobs', 'DE'),
            listing('Skopje to Berlin', 'rides', 'MK', destination: 'DE'),
          ]
        : country.contains('eq.CZ')
        ? [listing('Prague apartment', 'housing', 'CZ')]
        : [
            listing('German job', 'jobs', 'DE'),
            listing('Prague apartment', 'housing', 'CZ'),
          ];
    return response(items);
  }

  http.StreamedResponse response(List<Map<String, dynamic>> rows) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(rows))),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: http.Request(
          'GET',
          Uri.parse('https://fixture.example/rest/v1/listings'),
        ),
      );
}

Map<String, dynamic> listing(
  String title,
  String category,
  String country, {
  String? destination,
}) => {
  'id': title,
  'title': title,
  'category': category,
  'country_code': country,
  'description': 'Fixture advertisement',
  'city': '',
  'origin_country_code': destination == null ? null : country,
  'destination_country_code': destination,
};

void main() {
  test(
    'Every requested country is available and raw query input is rejected',
    () {
      for (final code in [
        'DE',
        'AT',
        'CZ',
        'SK',
        'NL',
        'BE',
        'DK',
        'NO',
        'SE',
        'CH',
      ]) {
        expect(listingCountry(code), isNotNull);
      }
      expect(
        () => listingCountryFilter('DE,status.eq.pending'),
        throwsArgumentError,
      );
    },
  );

  testWidgets('Country can be changed and reset independently of language', (
    tester,
  ) async {
    String? country;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CountrySelector(
              countryCode: country,
              language: 'mk',
              onChanged: (value) => setState(() => country = value),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇩🇪 Германија').last);
    await tester.pumpAndSettle();
    expect(country, 'DE');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌍 Сите држави').last);
    await tester.pumpAndSettle();
    expect(country, isNull);
  });

  testWidgets(
    'Country query includes ride endpoints; search/category still combine',
    (tester) async {
      final httpClient = FixtureClient();
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://fixture.example',
          'fixture-key',
          httpClient: httpClient,
        ),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      Widget page({
        String? country = 'DE',
        int category = -1,
        String search = '',
      }) => MaterialApp(
        home: Scaffold(
          body: PublishedListings(
            client: client,
            countryCode: country,
            selectedCategory: category,
            search: search,
            emptyMessage: 'No matching listings',
          ),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      final query = httpClient.requests.last.queryParameters;
      expect(query['status'], 'eq.published');
      expect(
        query['or'],
        '(country_code.eq.DE,and(category.eq.rides,or(origin_country_code.eq.DE,destination_country_code.eq.DE)))',
      );
      expect(find.text('German job'), findsOneWidget);
      expect(find.text('Skopje to Berlin'), findsOneWidget);
      expect(find.textContaining('→'), findsOneWidget);
      expect(find.text('Prague apartment'), findsNothing);
      final requestCount = httpClient.requests.length;
      await tester.pumpWidget(page(category: 0, search: 'Berlin'));
      await tester.pumpAndSettle();
      expect(httpClient.requests.length, requestCount);
      expect(find.text('Skopje to Berlin'), findsOneWidget);
      expect(find.text('German job'), findsNothing);
      await tester.pumpWidget(page(category: 1, search: 'Prague'));
      await tester.pumpAndSettle();
      expect(find.text('No matching listings'), findsOneWidget);
      await tester.pumpWidget(page(country: 'CZ'));
      await tester.pumpAndSettle();
      expect(find.text('Prague apartment'), findsOneWidget);
      expect(find.text('German job'), findsNothing);
      await tester.pumpWidget(page(country: null));
      await tester.pumpAndSettle();
      expect(
        httpClient.requests.last.queryParameters.containsKey('or'),
        isFalse,
      );
      expect(find.text('German job'), findsOneWidget);
      expect(find.text('Prague apartment'), findsOneWidget);
    },
  );

  testWidgets(
    'Switching country hides stale rows until the new response arrives',
    (tester) async {
      final httpClient = FixtureClient();
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://fixture.example',
          'fixture-key',
          httpClient: httpClient,
        ),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      Widget page(String code) => MaterialApp(
        home: Scaffold(
          body: PublishedListings(
            client: client,
            countryCode: code,
            selectedCategory: -1,
            search: '',
            emptyMessage: 'Nothing here',
          ),
        ),
      );
      await tester.pumpWidget(page('DE'));
      await tester.pumpAndSettle();
      final pending = Completer<http.StreamedResponse>();
      httpClient.nextResponse = pending;
      await tester.pumpWidget(page('CZ'));
      await tester.pump();
      expect(find.text('German job'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(httpClient.response([]));
      await tester.pumpAndSettle();
      expect(find.text('Nothing here'), findsOneWidget);
    },
  );

  testWidgets(
    'Posting inherits the selected country and includes all European countries',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CreateListingPage(initialCountryCode: 'NL')),
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).at(1),
            )
            .initialValue,
        'NL',
      );
      final field = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>).at(1),
      );
      for (final code in ['NL', 'BE', 'DK']) {
        expect(field.items!.any((item) => item.value == code), isTrue);
      }
    },
  );
}
