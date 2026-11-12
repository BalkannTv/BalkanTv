import 'package:flutter/material.dart';

import 'radio_backend.dart';
import 'radio_controller.dart';
import 'radio_stations.dart';

void openBalkanRadio(BuildContext context, RadioController radio) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RadioStationSheet(controller: radio),
  );
}

class RadioButton extends StatelessWidget {
  const RadioButton({super.key, required this.language, this.controller});
  final String language;
  final RadioController? controller;

  @override
  Widget build(BuildContext context) {
    final radio = controller ?? RadioController.shared;
    return AnimatedBuilder(
      animation: radio,
      builder: (context, _) => TextButton.icon(
        onPressed: () => openBalkanRadio(context, radio),
        icon: Icon(
          radio.status == RadioStatus.playing
              ? Icons.graphic_eq
              : Icons.radio_outlined,
          size: 21,
        ),
        label: Text(['mk', 'bg'].contains(language) ? 'Радио' : 'Radio'),
      ),
    );
  }
}

class RadioStationSheet extends StatefulWidget {
  const RadioStationSheet({super.key, required this.controller});
  final RadioController controller;
  @override
  State<RadioStationSheet> createState() => _RadioStationSheetState();
}

class _RadioStationSheetState extends State<RadioStationSheet> {
  String query = '';
  String? country;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio, color: Color(0xFF67D9FF)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Балканско радио',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    label: const Text('Minimize'),
                  ),
                  IconButton(
                    tooltip: 'Затвори прозорец (радиото продолжува)',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('Избери станица и слушај додека разгледуваш огласи.'),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Пребарај радио...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [null, ...radioStations.map((s) => s.country).toSet()]
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(item ?? 'Сите'),
                                selected: country == item,
                                onSelected: (_) =>
                                    setState(() => country = item),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    final items = radioStations
                        .where(
                          (station) =>
                              (country == null || country == station.country) &&
                              '${station.name} ${station.country}'
                                  .toLowerCase()
                                  .contains(query.trim().toLowerCase()),
                        )
                        .toList();
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Нема станици за ова пребарување.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final station = items[index];
                        final active = widget.controller.selected == station;
                        final status = widget.controller.status;
                        final playing = active && status == RadioStatus.playing;
                        final loading = active && status == RadioStatus.loading;
                        return Card(
                          color: active ? const Color(0xFF19395A) : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      playing
                                          ? Icons.graphic_eq
                                          : Icons.radio_outlined,
                                    ),
                            ),
                            title: Text(station.name),
                            subtitle: Text(
                              active && status == RadioStatus.error
                                  ? 'Станицата не е достапна. Обиди се повторно.'
                                  : station.country,
                            ),
                            trailing: IconButton(
                              tooltip: playing || loading
                                  ? 'Стоп'
                                  : 'Пушти ${station.name}',
                              icon: Icon(
                                playing || loading
                                    ? Icons.stop_circle
                                    : Icons.play_circle_fill,
                              ),
                              onPressed: () => playing || loading
                                  ? widget.controller.stop()
                                  : widget.controller.play(station),
                            ),
                            onTap: () => playing || loading
                                ? widget.controller.stop()
                                : widget.controller.play(station),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Избор од Balkan Radio Stanice · 19 станици',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RadioMiniPlayer extends StatelessWidget {
  const RadioMiniPlayer({super.key, this.controller});
  final RadioController? controller;
  @override
  Widget build(BuildContext context) {
    final radio = controller ?? RadioController.shared;
    return AnimatedBuilder(
      animation: radio,
      builder: (context, _) {
        final station = radio.selected;
        if (station == null) return const SizedBox.shrink();
        final loading = radio.status == RadioStatus.loading;
        final playing = radio.status == RadioStatus.playing;
        final error = radio.status == RadioStatus.error;
        return Material(
          color: const Color(0xFF19395A),
          child: SafeArea(
            top: false,
            child: ListTile(
              dense: true,
              onTap: () => openBalkanRadio(context, radio),
              leading: const Icon(Icons.radio, color: Color(0xFF67D9FF)),
              title: Text(
                station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                loading
                    ? 'Се поврзува...'
                    : error
                    ? 'Не е достапна · Обиди се повторно'
                    : playing
                    ? 'Во живо'
                    : 'Запрено',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Избери друга станица',
                    onPressed: () => openBalkanRadio(context, radio),
                    icon: const Icon(Icons.expand_less),
                  ),
                  loading
                  ? IconButton(
                      tooltip: 'Стоп',
                      onPressed: radio.stop,
                      icon: const Icon(Icons.stop_circle),
                    )
                  : IconButton(
                      tooltip: playing ? 'Стоп' : 'Пушти',
                      onPressed: () =>
                          playing ? radio.stop() : radio.play(station),
                      icon: Icon(
                        playing ? Icons.stop_circle : Icons.play_circle_fill,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
