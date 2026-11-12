import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Public hosted checkout link; no Stripe secret belongs in the app.
const stripeCoffeeUrl = 'https://buymeacoffee.com/balkan_connect';

class CoffeeSupport extends StatelessWidget {
  const CoffeeSupport({
    super.key,
    required this.language,
    this.compact = false,
    this.paymentUrl = stripeCoffeeUrl,
  });
  final String language;
  final bool compact;
  final String paymentUrl;

  @override
  Widget build(BuildContext context) {
    final mk = language == 'mk';
    final southSlavic = ['sr', 'bs', 'hr', 'me'].contains(language);
    final title = mk
        ? 'Части ме кафе'
        : southSlavic
        ? 'Časti me kafom'
        : 'Buy me a coffee';
    final description = mk
        ? 'Balkan Connect е бесплатен. Ако ти е корисен, можеш доброволно да нè поддржиш со едно кафе.'
        : southSlavic
        ? 'Balkan Connect je besplatan. Ako ti je koristan, možeš nas dobrovoljno podržati jednom kafom.'
        : 'Balkan Connect is free. If you find it useful, you can support us with a coffee. Entirely optional.';
    final uri = Uri.tryParse(paymentUrl);
    final ready =
        uri != null &&
        uri.scheme == 'https' &&
        ['buy.stripe.com', 'checkout.stripe.com', 'buymeacoffee.com'].contains(uri.host);
    final button = OutlinedButton.icon(
      icon: const Icon(Icons.coffee_outlined, color: Color(0xFFFFD18A)),
      label: Text(title),
      onPressed: () async {
        if (!ready) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                mk
                    ? 'Поддршката со кафе ќе биде достапна наскоро.'
                    : 'Coffee support will be available soon.',
              ),
            ),
          );
          return;
        }
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          if (!opened) throw StateError('Checkout could not open');
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                mk
                    ? 'Линкот не се отвори. Обиди се повторно.'
                    : 'Could not open checkout. Please try again.',
              ),
            ),
          );
        }
      },
    );
    if (compact) return button;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(description), const SizedBox(height: 12), button],
        ),
      ),
    );
  }
}

