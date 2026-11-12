import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'report_listing_page.dart';

class ReportsAdminPage extends StatefulWidget {
  const ReportsAdminPage({super.key});
  @override
  State<ReportsAdminPage> createState() => _ReportsAdminPageState();
}

class _ReportsAdminPageState extends State<ReportsAdminPage> {
  late Future<List<Map<String, dynamic>>> reports;
  bool busy = false;
  bool showClosed = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    reports = Supabase.instance.client
        .rpc('admin_listing_reports')
        .then((v) => List<Map<String, dynamic>>.from(v as List));
  }

  Future<void> review(Map<String, dynamic> report) async {
    final note = TextEditingController(
      text: report['admin_note']?.toString() ?? '',
    );
    String status = report['status'] == 'open'
        ? 'reviewing'
        : report['status'].toString();
    bool hide = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Review report / Разгледај пријава'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${report['listing_title']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(
                    'Listing: ${report['listing_id']}\nCurrent status: ${report['listing_status']}\nContact: ${report['listing_contact'] ?? ''}\n\n${report['listing_description'] ?? ''}',
                  ),
                  const Divider(),
                  SelectableText(
                    'Reporter: ${report['reporter_email'] ?? report['reporter_id']}\n${reportReasons[report['reason']] ?? report['reason']}\n\n${report['description']}',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['reviewing', 'resolved', 'dismissed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => update(() => status = v!),
                  ),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Private admin note / Забелешка',
                    ),
                  ),
                  if (report['listing_status'] == 'published')
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hide listing / Скриј го огласот'),
                      subtitle: const Text(
                        'Removes it from public results. Requires a resolution note.',
                      ),
                      value: hide,
                      onChanged: (v) => update(() {
                        hide = v!;
                        if (hide) status = 'resolved';
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save review'),
            ),
          ],
        ),
      ),
    );
    final text = note.text.trim();
    Future<void>.delayed(const Duration(milliseconds: 350), note.dispose);
    if (result != true || !mounted) return;
    if (hide && (status != 'resolved' || text.length < 5)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select resolved and explain why the listing is being hidden.',
          ),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await Supabase.instance.client.rpc(
        'review_listing_report',
        params: {
          'p_report_id': report['id'],
          'p_status': status,
          'p_note': text,
          'p_hide_listing': hide,
        },
      );
      if (mounted) setState(reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save review. Check your permissions and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Complaints / Пријави'),
      actions: [
        IconButton(
          onPressed: busy ? null : () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: reports,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load complaints. Administrator access is required.',
                ),
                TextButton(
                  onPressed: () => setState(reload),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!
            .where(
              (r) => showClosed || ['open', 'reviewing'].contains(r['status']),
            )
            .toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Reports are private. Review the description and listing before taking action.',
                ),
                SwitchListTile(
                  title: const Text('Include resolved and dismissed reports'),
                  value: showClosed,
                  onChanged: (v) => setState(() => showClosed = v),
                ),
                if (rows.isEmpty)
                  const ListTile(title: Text('No reports / Нема пријави')),
                ...rows.map(
                  (r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text('${r['listing_title']}'),
                      subtitle: Text(
                        '${reportReasons[r['reason']] ?? r['reason']}\n${r['status']} · ${r['created_at']}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: busy ? null : () => review(r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
