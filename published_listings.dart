import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublishedListings extends StatefulWidget {
  final int selectedCategory;
  final String search;
  final String emptyMessage;

  const PublishedListings({
    super.key,
    required this.selectedCategory,
    required this.search,
    required this.emptyMessage,
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

  void refresh() {
    listingsFuture = Supabase.instance.client
        .from('listings')
        .select(
          'id,title,description,category,country_code,'
          'city,contact_method,contact_value,created_at'
        )
        .eq('status', 'published')
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
                Text('${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(refresh),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final categories = ['jobs', 'rides', 'housing', 'services'];
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
          children: items.map((item) {
            String value(String key) => item[key]?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
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
                    Text(value('description')),
                    const SizedBox(height: 8),
                    Text(
                      '${value('country_code')} - ${value('city')}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact: ${value('contact_method')} '
                      '${value('contact_value')}',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
