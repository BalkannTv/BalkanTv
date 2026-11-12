import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_service.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final client = Supabase.instance.client;
  late final Future<String> roleFuture;

  List<Map<String, dynamic>> pending = [];
  bool loading = true;
  bool working = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    roleFuture = AdminService.getMyRole();
    roleFuture.then((role) {
      if (role == 'owner' || role == 'admin') {
        loadPending();
      }
    });
  }

  Future<void> loadPending() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await client
          .from('listings')
          .select(
            'id,title,description,category,country_code,'
            'city,contact_method,contact_value,created_at'
          )
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        pending = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  Future<void> review(String id, String status) async {
    if (working) return;

    setState(() => working = true);

    try {
      await client.rpc(
        'review_listing',
        params: {
          'p_listing_id': id,
          'p_status': status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Advertisement approved!'
                : 'Advertisement rejected!',
          ),
        ),
      );

      await loadPending();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget listingCard(Map<String, dynamic> item) {
    String field(String key) => item[key]?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field('title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(field('description')),
            const SizedBox(height: 8),
            Text('Category: ${field('category')}'),
            Text(
              'Location: ${field('country_code')} '
              '${field('city')}',
            ),
            Text(
              'Contact: ${field('contact_method')} '
              '${field('contact_value')}',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: working
                      ? null
                      : () => review(field('id'), 'approved'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () => review(field('id'), 'rejected'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: roleFuture,
      builder: (context, snapshot) {
        final role = snapshot.data;
        final allowed = role == 'owner' || role == 'admin';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Balkan Connect Admin'),
            actions: [
              if (allowed)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loadPending,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: !snapshot.hasData
              ? Center(
                  child: snapshot.hasError
                      ? const Text('Could not verify permissions.')
                      : const CircularProgressIndicator(),
                )
              : !allowed
                  ? const Center(child: Text('Access denied'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Your role: $role'),
                        const SizedBox(height: 20),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.people_outline),
                            title: const Text('Registered users'),
                            subtitle: const Text(
                              'Statistics coming next',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Pending advertisements (${pending.length})',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (loading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (errorMessage != null)
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          )
                        else if (pending.isEmpty)
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.check_circle_outline),
                              title: Text('No pending advertisements'),
                            ),
                          )
                        else
                          ...pending.map(listingCard),
                        const SizedBox(height: 16),
                        if (role == 'owner')
                          const Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.admin_panel_settings,
                              ),
                              title: Text('Manage administrators'),
                              subtitle: Text(
                                'Owner controls coming next',
                              ),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}
