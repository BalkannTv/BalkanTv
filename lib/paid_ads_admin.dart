import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_service.dart';
import 'ad_payment.dart';

import 'package:url_launcher/url_launcher.dart';

class PaidAdsAdminPage extends StatefulWidget {
  const PaidAdsAdminPage({super.key});

  @override
  State<PaidAdsAdminPage> createState() => _PaidAdsAdminPageState();
}

class _PaidAdsAdminPageState extends State<PaidAdsAdminPage> {
  final db = Supabase.instance.client;
  final business = TextEditingController();
  final image = TextEditingController();
  final link = TextEditingController();
  final price = TextEditingController(text: '0');
  final stripe = TextEditingController();
  bool allowed = false;
  bool ownerFree = true;
  String? error;

  String placement = 'banner';
  List<Map<String, dynamic>> ads = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadAds();
  }

  @override
  void dispose() {
    business.dispose();
    image.dispose();
    link.dispose();
    price.dispose();
    stripe.dispose();
    super.dispose();
  }

  Future<void> loadAds() async {
    try {
      final role = await AdminService.getMyRole();
      if (role != 'owner') {
        if (mounted) {
          setState(() {
            allowed = false;
            loading = false;
          });
        }
        return;
      }
      allowed = true;
      final data = await db.rpc('admin_paid_ads');
      final paymentLink = await loadAdPaymentLink();
      if (!mounted) return;
      setState(() {
        ads = List<Map<String, dynamic>>.from(data);
        stripe.text = paymentLink;
        error = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load advertisements. Please retry.';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> addAd() async {
    if (saving) return;
    if (business.text.trim().isEmpty) return;
    if (!validAdUrl(image.text) || !validAdUrl(link.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid HTTPS image and website URLs.'),
        ),
      );
      return;
    }

    final amount = ownerFree ? 0.0 : double.tryParse(price.text.trim());
    if (amount == null || amount < 0) return;

    setState(() => saving = true);

    try {
      // The advertising period begins on first activation.
      // Draft advertisements have no start or expiry date.

      if (ownerFree) {
        await db.rpc(
          'submit_paid_ad',
          params: {
            'p_business_name': business.text.trim(),
            'p_image_url': image.text.trim(),
            'p_target_url': link.text.trim(),
            'p_placement': placement,
          },
        );
      } else {
        await db.from('paid_ads').insert({
          'business_name': business.text.trim(),
          'image_url': image.text.trim(),
          'target_url': link.text.trim(),
          'placement': placement,
          'price_eur': amount,
        });
      }

      business.clear();
      image.clear();
      link.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advertisement saved as draft')),
      );
      await loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> confirmPayment(Map<String, dynamic> ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Have you verified receiving EUR ${ad['price_eur']} '
          'from ${ad['business_name']}? '
          'Only confirm after checking your bank or Stripe account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || saving) return;
    setState(() => saving = true);

    try {
      await db.rpc('confirm_paid_ad', params: {'p_ad_id': ad['id']});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment manually confirmed')),
      );
      await loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment confirmation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> toggleAd(Map<String, dynamic> ad) async {
    if (saving) return;
    final active = ad['status'] == 'active';

    if (!active && ad['payment_status'] != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm payment before activation.')),
      );
      return;
    }

    if (!active) {
      final approve = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approve and publish advertisement?'),
          content: Text(
            'Confirm you reviewed the image and website for ${ad['business_name']}. Its 30-day period begins on first publication.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve and publish'),
            ),
          ],
        ),
      );
      if (approve != true || !mounted) return;
    }
    setState(() => saving = true);
    try {
      if (active) {
        await db.rpc('pause_paid_ad', params: {'p_ad_id': ad['id']});
      } else {
        await db.rpc('activate_paid_ad', params: {'p_ad_id': ad['id']});
      }

      await loadAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveStripe() async {
    if (saving) return;
    if (!validStripeLink(stripe.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid https://buy.stripe.com/ Payment Link.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await db.rpc(
        'set_ad_payment_link',
        params: {'p_link': stripe.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stripe Payment Link saved')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save Stripe link. Owner access is required.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Advertising'),
        actions: [
          IconButton(
            onPressed: saving ? null : loadAds,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : !allowed
          ? const Center(child: Text('Owner access required'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null)
                  TextButton(onPressed: loadAds, child: Text('$error Retry')),
                const Text(
                  'Stripe payments · €9.99 / 30 days',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Use a one-time €9.99 EUR Payment Link with quantity fixed at 1. Check successful payment in Stripe using the advertisement reference and customer email. A checkout return or customer claim does not confirm payment.',
                ),
                TextField(
                  controller: stripe,
                  decoration: const InputDecoration(
                    labelText: 'Stripe Payment Link',
                    hintText: 'https://buy.stripe.com/...',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: saving ? null : saveStripe,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Stripe link'),
                ),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Create advertisement as owner'),
                  children: [
                    CheckboxListTile(
                      title: const Text(
                        'My advertisement — free / Моја реклама — бесплатно',
                      ),
                      subtitle: const Text(
                        'Owner only. You can publish it without a Stripe payment.',
                      ),
                      value: ownerFree,
                      onChanged: saving
                          ? null
                          : (v) => setState(() {
                              ownerFree = v!;
                              price.text = ownerFree ? '0' : '9.99';
                            }),
                    ),
                    const Text(
                      'Create advertisement',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: business,
                      decoration: const InputDecoration(
                        labelText: 'Business name',
                      ),
                    ),
                    TextField(
                      controller: image,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    TextField(
                      controller: link,
                      decoration: const InputDecoration(
                        labelText: 'Website URL',
                      ),
                    ),
                    TextField(
                      controller: price,
                      enabled: !ownerFree,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price EUR'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: placement,
                      items: const [
                        DropdownMenuItem(
                          value: 'banner',
                          child: Text('Top banner'),
                        ),
                        DropdownMenuItem(
                          value: 'sidebar',
                          child: Text('Sidebar'),
                        ),
                        DropdownMenuItem(
                          value: 'feed',
                          child: Text('Between listings'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => placement = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: saving ? null : addAd,
                      icon: const Icon(Icons.add),
                      label: const Text('Save advertisement'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Advertisements',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...ads.map(
                    (ad) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ad['business_name']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SelectableText(
                              'Reference: ${ad['id']}\nCustomer: ${ad['customer_email'] ?? 'Owner-created'}',
                            ),
                            Text(
                              '${ad['placement']} • €${ad['price_eur']}'
                              ' • ${ad['status']} • ${ad['payment_status']}',
                            ),
                            if (ad['price_eur'] == 0 &&
                                ad['payment_status'] == 'paid')
                              const Text(
                                'Owner advertisement — free / Сопственичка реклама — бесплатно',
                              ),
                            if (validAdUrl(ad['image_url']?.toString() ?? ''))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Image.network(
                                  ad['image_url'].toString(),
                                  height: 160,
                                  width: 500,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, error, stack) => const Text(
                                    'Image unavailable. Check the supplied URL.',
                                  ),
                                ),
                              ),
                            SelectableText('Website: ${ad['target_url']}'),
                            if (validAdUrl(ad['target_url']?.toString() ?? ''))
                              TextButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse(ad['target_url'].toString()),
                                  mode: LaunchMode.externalApplication,
                                  webOnlyWindowName: '_blank',
                                ),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Review website'),
                              ),
                            if (ad['expires_at'] != null)
                              Text('Expires: ${ad['expires_at']}'),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if (ad['payment_status'] == 'unpaid')
                                  OutlinedButton.icon(
                                    label: const Text('Confirm Stripe payment'),
                                    icon: const Icon(Icons.payments_outlined),
                                    onPressed: saving
                                        ? null
                                        : () => confirmPayment(ad),
                                  ),
                                FilledButton.icon(
                                  label: Text(
                                    ad['status'] == 'active'
                                        ? 'Pause advertisement'
                                        : 'Approve and publish',
                                  ),
                                  icon: Icon(
                                    ad['status'] == 'active'
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                  onPressed:
                                      saving ||
                                          (ad['status'] != 'active' &&
                                              ad['payment_status'] != 'paid')
                                      ? null
                                      : () => toggleAd(ad),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
