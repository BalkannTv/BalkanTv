import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class BalkanRadioBar extends StatefulWidget {
  const BalkanRadioBar({super.key});
  @override
  State<BalkanRadioBar> createState() => _BalkanRadioBarState();
}

class _BalkanRadioBarState extends State<BalkanRadioBar> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _url = TextEditingController();
  bool _expanded = false;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();
      } else if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        final stream = _url.text.trim();
        final uri = Uri.tryParse(stream);
        if (uri == null || !uri.hasScheme || !['http','https'].contains(uri.scheme)) {
          setState(() { _expanded = true; _error = 'Enter a valid radio stream URL (https://...)'; });
          return;
        }
        await _player.play(UrlSource(stream));
      }
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() { _error = 'Stream unavailable: $e'; _expanded = true; });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF102A48),
      elevation: 10,
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(children: [
            TextField(controller: _url,
              decoration: const InputDecoration(labelText: 'Radio stream URL',
                hintText: 'https://station.example/live.mp3',
                isDense: true, border: OutlineInputBorder())),
            if (_error != null) Padding(padding: const EdgeInsets.all(5),
              child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
          ]),
        ),
        Row(children: [
          const SizedBox(width: 12),
          const Icon(Icons.radio, color: Colors.lightBlueAccent),
          const SizedBox(width: 8),
          const Expanded(child: Text('Balkan Radio', style: TextStyle(fontWeight: FontWeight.bold))),
          IconButton(tooltip: _playing ? 'Pause radio' : 'Play radio',
            onPressed: _toggle, icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle, size: 30)),
          IconButton(tooltip: _expanded ? 'Minimize player' : 'Expand player',
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up)),
        ]),
      ])),
    );
  }
}
