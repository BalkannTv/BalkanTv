import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balkan_connect/radio_backend.dart';
import 'package:balkan_connect/radio_button.dart';
import 'package:balkan_connect/radio_controller.dart';
import 'package:balkan_connect/radio_stations.dart';

class FakeRadioBackend implements RadioBackend {
  final changes = StreamController<RadioStatus>.broadcast();
  final played = <String>[];
  bool fail = false;
  int stops = 0;
  Completer<void>? pending;
  @override
  Stream<RadioStatus> get events => changes.stream;
  @override
  Future<void> play(String url) async {
    played.add(url);
    if (fail) throw StateError('Offline');
    await pending?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    await changes.close();
  }
}

void main() {
  test('Switching stations uses the selected audio stream', () async {
    final backend = FakeRadioBackend();
    final controller = RadioController(backend);
    await controller.play(radioStations[0]);
    await controller.play(radioStations[1]);
    expect(backend.played, [
      radioStations[0].streamUrl,
      radioStations[1].streamUrl,
    ]);
    expect(controller.selected, radioStations[1]);
    expect(controller.status, RadioStatus.playing);
    controller.dispose();
  });
  test(
    'Stop during connection cannot be undone by a late completion',
    () async {
      final backend = FakeRadioBackend()..pending = Completer<void>();
      final controller = RadioController(backend);
      final play = controller.play(radioStations[0]);
      await controller.stop();
      backend.pending!.complete();
      await play;
      expect(controller.status, RadioStatus.stopped);
      expect(backend.stops, 1);
      controller.dispose();
    },
  );
  test('An unavailable stream can be retried', () async {
    final backend = FakeRadioBackend()..fail = true;
    final controller = RadioController(backend);
    await controller.play(radioStations[0]);
    expect(controller.status, RadioStatus.error);
    backend.fail = false;
    await controller.play(radioStations[0]);
    expect(controller.status, RadioStatus.playing);
    controller.dispose();
  });
  testWidgets(
    'Radio opens an internal station list and keeps playing when closed',
    (tester) async {
      final backend = FakeRadioBackend();
      final controller = RadioController(backend);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(language: 'mk', controller: controller),
            bottomNavigationBar: RadioMiniPlayer(controller: controller),
          ),
        ),
      );
      await tester.tap(find.text('Радио'));
      await tester.pumpAndSettle();
      expect(find.text('Балканско радио'), findsOneWidget);
      await tester.tap(find.text(radioStations[0].name));
      await tester.pumpAndSettle();
      expect(backend.played.single, radioStations[0].streamUrl);
      await tester.tap(find.byTooltip('Затвори прозорец (радиото продолжува)'));
      await tester.pumpAndSettle();
      expect(find.text('Балканско радио'), findsNothing);
      expect(find.text('Во живо'), findsOneWidget);
      expect(controller.status, RadioStatus.playing);
      await tester.tap(find.byTooltip('Стоп').first);
      await tester.pumpAndSettle();
      expect(controller.status, RadioStatus.stopped);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
