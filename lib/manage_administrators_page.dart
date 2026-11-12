import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageAdministratorsPage extends StatefulWidget {
  const ManageAdministratorsPage({super.key});
  @override
  State<ManageAdministratorsPage> createState() =>
      _ManageAdministratorsPageState();
}

class _ManageAdministratorsPageState extends State<ManageAdministratorsPage> {
  final email = TextEditingController();
  late Future<List<Map<String, dynamic>>> administrators;
  Map<String, dynamic>? candidate;
  bool working = false;
  String? message;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  void reload() {
    administrators = Supabase.instance.client
        .rpc('owner_administrators')
        .then((rows) => List<Map<String, dynamic>>.from(rows as List));
  }

  Future<void> search() async {
    if (working) return;
    final value = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      setState(() {
        candidate = null;
        message =
            'Enter the registered email address / Внеси регистрирана е-пошта';
      });
      return;
    }
    setState(() {
      working = true;
      candidate = null;
      message = null;
    });
    try {
      final rows = List<Map<String, dynamic>>.from(
        await Supabase.instance.client.rpc(
          'owner_find_administrator',
          params: {'p_email': value},
        ) as List,
      );
      if (mounted) {
        setState(() {
          candidate = rows.isEmpty ? null : rows.single;
          if (rows.isEmpty) message = 'No verified account found. Ask this person to register and verify their email first.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Could not search. Owner access is required.');
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> change(Map<String, dynamic> account, bool enable) async {
    if (working || account['role'] == 'owner') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          enable
              ? 'Approve administrator / Одобри администратор'
              : 'Remove administrator / Отстрани администратор',
        ),
        content: Text(
          '${account['email']}\n\n${enable ? 'This person can approve or reject listings and review complaints. They cannot manage administrators, Stripe or paid advertising.' : 'This person will lose moderation access. Their account and listings will remain.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => working = true);
    try {
      await Supabase.instance.client.rpc(
        'owner_set_administrator',
        params: {'p_user_id': account['user_id'], 'p_enable': enable},
      );
      if (mounted) {
        setState(() {
          candidate = null;
          email.clear();
          message = enable
              ? 'Administrator approved / Администраторот е одобрен'
              : 'Administrator access removed / Администраторскиот пристап е отстранет';
          reload();
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              message = 'Could not update administrator access. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget accountCard(Map<String, dynamic> account) {
    final owner = account['role'] == 'owner';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              '${account['email']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              owner
                  ? 'Owner / Сопственик'
                  : account['role'] == 'admin'
                  ? 'Administrator / Администратор'
                  : 'Registered user / Корисник',
            ),
            if (owner)
              const Text(
                'Protected owner account / Заштитен сопственички профил',
              )
            else
              OutlinedButton.icon(
                onPressed: working
                    ? null
                    : () => change(account, account['role'] != 'admin'),
                icon: Icon(
                  account['role'] == 'admin'
                      ? Icons.person_remove_outlined
                      : Icons.person_add_alt_1,
                ),
                label: Text(
                  account['role'] == 'admin'
                      ? 'Remove administrator'
                      : 'Approve administrator',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administrators / Администратори'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: working ? null : () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: administrators,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Owner access required. Could not load administrators.',
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Only you approve administrators. They moderate listings and complaints. Paid advertising, Stripe and administrator management remain owner-only.\n\nСамо ти назначуваш администратори. Тие управуваат со огласите и пријавите, а платените реклами и Stripe остануваат само за тебе.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: email,
                  enabled: !working,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Registered email / Регистрирана е-пошта',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => search(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: working ? null : search,
                  icon: const Icon(Icons.search),
                  label: Text(
                    working ? 'Please wait…' : 'Find account / Пронајди профил',
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(message!),
                  ),
                if (candidate != null) accountCard(candidate!),
                const SizedBox(height: 24),
                const Text(
                  'Current administrators / Тековни администратори',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ...snapshot.data!.map(accountCard),
              ],
            ),
          ),
        );
      },
    ),
  );
}
