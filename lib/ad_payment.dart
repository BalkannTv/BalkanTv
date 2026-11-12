import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

bool validAdUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return value.trim().length <= 2048 &&
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.contains('.') &&
      uri.userInfo.isEmpty &&
      !value.contains(RegExp(r'\s'));
}

bool validStripeLink(String value) =>
    RegExp(r'^https://buy\.stripe\.com/[A-Za-z0-9_]+$').hasMatch(value.trim());

Future<String> loadAdPaymentLink() async {
  final row = await Supabase.instance.client
      .from('ad_settings')
      .select('stripe_payment_link')
      .eq('id', true)
      .single();
  return row['stripe_payment_link'] as String? ?? '';
}

Future<void> payForAd(BuildContext context, String link, String adId) async {
  if (!validStripeLink(link)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Stripe payment is not configured yet. Your draft is saved; please try later.',
        ),
      ),
    );
    return;
  }
  try {
    final uri = Uri.parse(link.trim())
        .replace(queryParameters: {'client_reference_id': adId});
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    )) {
      throw StateError('Payment page unavailable');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Stripe. Your draft is saved; try again.',
          ),
        ),
      );
    }
  }
}

class AdPaymentCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final String stripeLink;
  const AdPaymentCard({super.key, required this.ad, required this.stripeLink});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ad['business_name']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            ad['price_eur'] == 0 && ad['payment_status'] == 'paid'
                ? 'Owner advertisement — free · ${ad['status']}'
                : '€${ad['price_eur']} · 30 days · ${ad['status']} · ${ad['payment_status']}',
          ),
          if (ad['expires_at'] != null) Text('Expires: ${ad['expires_at']}'),
          SelectableText('Reference: ${ad['id']}'),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: ad['id'].toString()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reference copied')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy reference'),
          ),
          if (ad['payment_status'] == 'unpaid') ...[
            const Text(
              'Pay once through Stripe using the same email as your account. Do not pay again if you have already paid. The owner verifies payment and reviews your advertisement before publishing. The 30 days start when it is published.',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: validStripeLink(stripeLink)
                  ? () => payForAd(context, stripeLink, ad['id'].toString())
                  : null,
              icon: const Icon(Icons.payment),
              label: const Text('Pay €9.99 with Stripe'),
            ),
            if (!validStripeLink(stripeLink))
              const Text(
                'Stripe payment will be available shortly. Your draft is saved.',
              ),
          ],
        ],
      ),
    ),
  );
}
