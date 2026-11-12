import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaidAdsBanner extends StatefulWidget {
  const PaidAdsBanner({super.key});

  @override
  State<PaidAdsBanner> createState() => _PaidAdsBannerState();
}

class _PaidAdsBannerState extends State<PaidAdsBanner> {
  List<Map<String, dynamic>> ads = [];

  @override
  void initState() {
    super.initState();
    loadAds();
  }

  Future<void> loadAds() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final result = await Supabase.instance.client
          .from('paid_ads')
          .select('business_name,image_url,target_url')
          .eq('placement', 'banner')
          .eq('status', 'active')
          .eq('payment_status', 'paid')
          .lte('starts_at', now)
          .gt('expires_at', now);

      if (!mounted) return;
      setState(() {
        ads = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint('Paid ads loading error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty && kDebugMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF071A34), Color(0xFF145C91)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Color(0xFF29B6F6)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DEMO • Sponsored',
                    style: TextStyle(
                      color: Color(0xFFFFD18A),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BLiZ TV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Live TV • Movies • Series • Sports',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://bliztv.online');
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Visit BLiZ TV'),
              ),
            ],
          ),
        ),
      );
    }

    if (ads.isEmpty) return const SizedBox.shrink();

    return Column(
      children: ads.map((ad) {
        final image = ad['image_url']?.toString() ?? '';
        final link = ad['target_url']?.toString() ?? '';
        final uri = Uri.tryParse(link);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: uri?.scheme == 'https'
                ? () => launchUrl(
                    uri!,
                    mode: LaunchMode.externalApplication,
                  )
                : null,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF132C49),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  if (image.startsWith('https://'))
                    Image.network(
                      image,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  Text(
                    ad['business_name']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

