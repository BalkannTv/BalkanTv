import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ad_payment.dart';
import 'auth_page.dart';
import 'admin_service.dart';

class CreatePaidAdPage extends StatefulWidget {
  const CreatePaidAdPage({super.key});

  @override
  State<CreatePaidAdPage> createState() => _CreatePaidAdPageState();
}

class _CreatePaidAdPageState extends State<CreatePaidAdPage> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _image = TextEditingController();
  final _website = TextEditingController();

  String _placement = 'banner';
  bool _saving = false;
  String _stripeLink = '';
  String? _error;
  bool _loading = true;
  bool _owner = false;
  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await loadAdPaymentLink();
      final owner = await AdminService.getMyRole() == 'owner';
      final rows = Supabase.instance.client.auth.currentUser == null
          ? <dynamic>[]
          : await Supabase.instance.client.rpc('my_paid_ads');
      if (mounted) {
        setState(() {
          _stripeLink = link;
          _owner = owner;
          _ads = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your advertisements. Please retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _business.dispose();
    _image.dispose();
    _website.dispose();
    super.dispose();
  }

  bool _validUrl(String value) {
    return validAdUrl(value);
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }

    setState(() => _saving = true);

    try {
      final adId = await Supabase.instance.client.rpc(
        'submit_paid_ad',
        params: {
          'p_business_name': _business.text.trim(),
          'p_image_url': _image.text.trim(),
          'p_target_url': _website.text.trim(),
          'p_placement': _placement,
        },
      );

      if (!mounted) return;

      _business.clear();
      _image.clear();
      _website.clear();
      await _load();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Advertisement submitted'),
          content: Text(
            _owner
                ? 'Your owner advertisement is free. Open Paid Advertising Management to review and publish it. Reference: $adId'
                : 'Your advertisement has been saved as a draft. '
                      'It will not appear publicly until payment '
                      'is verified and an administrator activates it. '
                      'Price: €9.99 for 30 days from publication. '
                      'Use Pay with Stripe in My advertisements below. Reference: $adId',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is PostgrestException
                ? e.message
                : 'Could not submit the advertisement. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Advertisement'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Advertise on Balkan Connect',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _owner
                      ? 'Your owner advertisements are free. Submit the draft here, then review and publish it in your Paid Advertising Management screen.'
                      : 'Create your advertisement and submit it '
                            'for review. €9.99 for 30 days, paid once through Stripe. '
                            'The owner checks both the advertisement and payment before publishing. '
                            'The 30 days start on publication.',
                ),
                const SizedBox(height: 24),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  TextButton(onPressed: _load, child: Text('$_error Retry')),
                if (_ads.isNotEmpty) ...[
                  const Text(
                    'My advertisements / Мои реклами',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ..._ads.map(
                    (ad) => AdPaymentCard(ad: ad, stripeLink: _stripeLink),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _business,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Enter your business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _image,
                  decoration: const InputDecoration(
                    labelText: 'Advertisement image URL',
                    hintText: 'https://example.com/banner.jpg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_validUrl(value ?? '')) {
                      return 'Enter a valid HTTPS image URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _website,
                  decoration: const InputDecoration(
                    labelText: 'Website URL',
                    hintText: 'https://example.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_validUrl(value ?? '')) {
                      return 'Enter a valid HTTPS website URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _placement,
                  decoration: const InputDecoration(
                    labelText: 'Advertisement placement',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'banner',
                      child: Text('Top banner'),
                    ),
                    DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
                    DropdownMenuItem(
                      value: 'feed',
                      child: Text('Between listings'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _placement = value);
                          }
                        },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: const Icon(Icons.campaign),
                  label: Text(
                    _saving ? 'Submitting...' : 'Submit advertisement',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Submitting an advertisement does not '
                  'activate it or confirm payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
