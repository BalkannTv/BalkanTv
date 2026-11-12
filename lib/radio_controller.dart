import 'dart:async';

import 'package:flutter/foundation.dart';

import 'radio_backend.dart';
import 'radio_backend_native.dart'
    if (dart.library.js_interop) 'radio_backend_web.dart'
    as platform;
import 'radio_stations.dart';

class RadioController extends ChangeNotifier {
  RadioController(this._backend) {
    _subscription = _backend.events.listen((status) {
      if (_disposed || selected == null) return;
      // Stop is immediate, even when an old connection completes later.
      if (this.status == RadioStatus.stopped) return;
      this.status = status;
      notifyListeners();
    });
  }
  static final shared = RadioController(platform.createRadioBackend());
  final RadioBackend _backend;
  late final StreamSubscription<RadioStatus> _subscription;
  RadioStation? selected;
  RadioStatus status = RadioStatus.stopped;
  int _request = 0;
  bool _disposed = false;

  Future<void> play(RadioStation station) async {
    final request = ++_request;
    selected = station;
    status = RadioStatus.loading;
    notifyListeners();
    try {
      await _backend.play(station.streamUrl);
      if (_disposed || request != _request) return;
      status = RadioStatus.playing;
    } catch (_) {
      if (_disposed || request != _request) return;
      status = RadioStatus.error;
      // Release a failed connection so it cannot begin playing after timeout.
      try {
        await _backend.stop();
      } catch (_) {}
      if (_disposed || request != _request) return;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    ++_request;
    status = RadioStatus.stopped;
    notifyListeners();
    try {
      await _backend.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    unawaited(_subscription.cancel());
    unawaited(_backend.dispose());
    super.dispose();
  }
}
