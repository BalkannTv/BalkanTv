import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balkan_connect/main.dart';
import 'package:balkan_connect/marketplace_home.dart';

import 'country_filter_test.dart' show FixtureClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://fixture.example',
      publishableKey: 'fixture-key',
      httpClient: FixtureClient(),
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'Categories and country selector appear early at $size without overflow',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: MarketplaceHome(
                language: 'mk',
                onLanguageChanged: (_) {},
                uiTexts: translations['mk']!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getTopLeft(find.text('Категории')).dy, lessThan(460));
        expect(find.text('🌍 Сите држави'), findsWidgets);
        expect(find.text('🇲🇰'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Части ме кафе'), 400,
            scrollable: find.byType(Scrollable).first);
        expect(find.text('Части ме кафе'), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
