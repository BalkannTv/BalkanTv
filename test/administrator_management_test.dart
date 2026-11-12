import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balkan_connect/manage_administrators_page.dart';

class AdministratorFixture extends http.BaseClient {
  final calls = <String>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    calls.add(path);
    final data = path.endsWith('owner_administrators')
        ? [
            {
              'user_id': 'owner-id',
              'email': 'owner@example.test',
              'role': 'owner',
            },
          ]
        : [
            {
              'user_id': 'candidate-id',
              'email': 'moderator@example.test',
              'role': 'user',
            },
          ];
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(data))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets(
    'Owner is protected and cancelling a moderator approval makes no permission change',
    (tester) async {
      final fixture = AdministratorFixture();
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
      await tester.pumpWidget(
        const MaterialApp(home: ManageAdministratorsPage()),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Protected owner account / Заштитен сопственички профил'),
        findsOneWidget,
      );
      expect(find.text('Remove administrator'), findsNothing);
      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.text('Find account / Пронајди профил'));
      await tester.pump();
      expect(
        fixture.calls.where((c) => c.endsWith('owner_find_administrator')),
        isEmpty,
      );
      await tester.enterText(find.byType(TextField), 'moderator@example.test');
      await tester.tap(find.text('Find account / Пронајди профил'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Approve administrator'));
      await tester.tap(find.text('Approve administrator'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'They cannot manage administrators, Stripe or paid advertising.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        fixture.calls.where((c) => c.endsWith('owner_set_administrator')),
        isEmpty,
      );
    },
  );
}
