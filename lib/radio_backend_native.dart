import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'radio_backend.dart';

RadioBackend createRadioBackend() => NativeRadioBackend();

class NativeRadioBackend implements RadioBackend {
  final _events = StreamController<RadioStatus>.broadcast();
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _subscription;
  int _version = 0;
  @override
  Stream<RadioStatus> get events => _events.stream;

  @override
  Future<void> play(String url) async {
    final version = ++_version;
    await _retire();
    if (version != _version) return;
    final player = _player = AudioPlayer();
    _subscription = player.onPlayerStateChanged.listen((state) {
      if (version != _version) return;
      if (state == PlayerState.playing) _events.add(RadioStatus.playing);
      if (state == PlayerState.completed) _events.add(RadioStatus.stopped);
    });
    AudioPlayer.preparationTimeout = const Duration(seconds: 15);
    await player.play(UrlSource(url));
  }

  @override
  Future<void> stop() async {
    ++_version;
    await _retire();
  }

  Future<void> _retiring = Future.value();
  Future<void> _retire() {
    final player = _player;
    final subscription = _subscription;
    _player = null;
    _subscription = null;
    return _retiring = _retiring.catchError((Object _) {}).then((_) async {
      await subscription?.cancel();
      if (player != null) {
        await player.stop();
        await player.dispose();
      }
    });
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
