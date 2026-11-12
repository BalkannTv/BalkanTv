import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';

const reportReasons = {
  'suspected_fraud': 'Suspected fraud / Сомнеж за измама',
  'misleading_description': 'Misleading description / Неточен опис',
  'terms_not_met': 'Terms not met / Непочитувани услови',
  'other': 'Other / Друго',
};

class ReportListingPage extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  const ReportListingPage({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });
  @override
  State<ReportListingPage> createState() => _ReportListingPageState();
}

class _ReportListingPageState extends State<ReportListingPage> {
  final form = GlobalKey<FormState>();
  final description = TextEditingController();
  String reason = 'suspected_fraud';
  bool sending = false;
  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (sending || !form.currentState!.validate()) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    setState(() => sending = true);
    try {
      await Supabase.instance.client.rpc(
        'submit_listing_report',
        params: {
          'p_listing_id': widget.listingId,
          'p_reason': reason,
          'p_description': description.text.trim(),
        },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Report received / Пријавата е примена'),
          content: const Text(
            'The administrator will review your report. It is private and does not automatically remove the listing.\n\nАдминистраторот ќе ја разгледа пријавата. Таа не е јавна.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send the report. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report a problem / Пријави проблем')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.listingTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Explain what happened and which advertised conditions were not met. Do not include passwords, payment card details or identity documents.\n\nОпиши што се случило и кои услови не биле почитувани. Не внесувај лозинки, картички или лични документи.',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: reason,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reason / Причина',
                ),
                items: reportReasons.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: sending ? null : (v) => setState(() => reason = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: description,
                minLines: 5,
                maxLines: 10,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'What happened? / Што се случи?',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().length < 20
                    ? 'Please describe the problem in at least 20 characters.'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: sending ? null : submit,
                icon: const Icon(Icons.flag_outlined),
                label: Text(
                  sending ? 'Sending…' : 'Send report / Испрати пријава',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
