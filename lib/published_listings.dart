import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'listing_countries.dart';
import 'listing_contact.dart';
import 'report_listing_page.dart';
import 'rotating_ads.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class PublishedListings extends StatefulWidget {
  final int selectedCategory;
  final String search;
  final String emptyMessage;
  final String? countryCode;
  final String language;
  final SupabaseClient? client;

  const PublishedListings({
    super.key,
    required this.selectedCategory,
    required this.search,
    required this.emptyMessage,
    this.countryCode,
    this.language = 'en',
    this.client,
  });

  @override
  State<PublishedListings> createState() => _PublishedListingsState();
}

class _PublishedListingsState extends State<PublishedListings> {
  late Future<List<Map<String, dynamic>>> listingsFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(covariant PublishedListings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode ||
        oldWidget.client != widget.client) {
      refresh();
    }
  }

  void refresh() {
    var query = (widget.client ?? Supabase.instance.client)
        .from('listings')
        .select(
          'id,title,description,category,country_code,'
          'city,contact_method,contact_value,created_at,'
          'origin_country_code,destination_country_code',
        )
        .eq('status', 'published');
    if (widget.countryCode != null) {
      query = query.or(listingCountryFilter(widget.countryCode!));
    }
    listingsFuture = query
        .order('created_at', ascending: false)
        .then((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Could not load advertisements'),
                const SizedBox(height: 8),
                const Text('Check your connection and try again.'),
                TextButton(
                  onPressed: () => setState(refresh),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final categories = [
          'rides',
          'jobs',
          'housing',
          'vehicles',
          'home_goods',
          'electronics',
          'services',
          'other',
        ];
        final search = widget.search.trim().toLowerCase();

        final items = (snapshot.data ?? []).where((item) {
          if (widget.selectedCategory >= 0 &&
              item['category'] != categories[widget.selectedCategory]) {
            return false;
          }

          if (search.isEmpty) return true;

          final searchable = [
            item['title'],
            item['description'],
            item['city'],
            item['country_code'],
          ].join(' ').toLowerCase();

          return searchable.contains(search);
        }).toList();

        if (items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(widget.emptyMessage)),
            ),
          );
        }

        return Column(
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            String value(String key) => item[key]?.toString() ?? '';
            String countryName(String code) =>
                listingCountry(code)?.label(widget.language) ?? code;
            final origin = value('origin_country_code');
            final destination = value('destination_country_code');
            final location =
                item['category'] == 'rides' && destination.isNotEmpty
                ? '${countryName(origin.isEmpty ? value('country_code') : origin)} → ${countryName(destination)}'
                : countryName(value('country_code'));
            final locationText = [
              location,
              value('city'),
            ].where((s) => s.isNotEmpty).join(' · ');

            return Column(
              children: [
                if (entry.key > 0 && entry.key % 5 == 0)
                  const RotatingAds(placement: 'feed'),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(value('title')),
                        content: SingleChildScrollView(
                          child: SelectableText(
                            [
                              value('description'),
                              locationText,
                              value('contact_value'),
                            ].where((text) => text.isNotEmpty).join('\n\n'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      value('title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          value('description'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(locationText),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: Text(
                            widget.language == 'mk'
                                ? 'Пријави проблем'
                                : 'Report a problem',
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportListingPage(
                                listingId: value('id'),
                                listingTitle: value('title'),
                              ),
                            ),
                          ),
                        ),
                        if (value('contact_method') == 'whatsapp' &&
                            whatsappContactUri(value('contact_value')) != null)
                          TextButton.icon(
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('WhatsApp'),
                            onPressed: () async {
                              try {
                                final opened = await launchUrl(
                                  whatsappContactUri(value('contact_value'))!,
                                  mode: LaunchMode.externalApplication,
                                  webOnlyWindowName: '_blank',
                                );
                                if (!opened) {
                                  throw StateError('Could not open contact');
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open WhatsApp. Copy the number instead.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        if (value('contact_value').isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(value('contact_value')),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: value('contact_value')),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contact copied')),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
