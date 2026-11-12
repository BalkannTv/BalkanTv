import 'dart:async';

enum RadioStatus { stopped, loading, playing, error }

abstract class RadioBackend {
  Stream<RadioStatus> get events;
  Future<void> play(String url);
  Future<void> stop();
  Future<void> dispose();
}
