import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'radio_backend.dart';

RadioBackend createRadioBackend() => WebRadioBackend();

/// A plain media element also supports stations without CORS headers.
class WebRadioBackend implements RadioBackend {
  final _events = StreamController<RadioStatus>.broadcast();
  web.HTMLAudioElement? _audio;
  @override
  Stream<RadioStatus> get events => _events.stream;

  @override
  Future<void> play(String url) {
    _release();
    final audio = _audio = web.HTMLAudioElement();
    audio.id = 'balkan-radio-audio';
    audio.style.display = 'none';
    web.document.body?.appendChild(audio);
    audio.preload = 'none';
    audio.src = url;
    void emit(RadioStatus state) {
      if (identical(_audio, audio) && !_events.isClosed) _events.add(state);
    }

    audio.onplaying = ((web.Event _) => emit(RadioStatus.playing)).toJS;
    audio.onwaiting = ((web.Event _) => emit(RadioStatus.loading)).toJS;
    audio.onerror = ((web.Event _) => emit(RadioStatus.error)).toJS;
    audio.onended = ((web.Event _) => emit(RadioStatus.stopped)).toJS;
    // Invoke play synchronously within the user's click for browser autoplay rules.
    return audio.play().toDart.timeout(const Duration(seconds: 15));
  }

  void _release() {
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      audio.pause();
      audio.removeAttribute('src');
      audio.load();
      audio.remove();
    }
  }

  @override
  Future<void> stop() async => _release();

  @override
  Future<void> dispose() async {
    _release();
    await _events.close();
  }
}
