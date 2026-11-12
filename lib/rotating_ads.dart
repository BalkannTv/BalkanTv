import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RotatingAds extends StatefulWidget {
  final String placement;

  const RotatingAds({
    super.key,
    required this.placement,
  });

  @override
  State<RotatingAds> createState() => _RotatingAdsState();
}

class _RotatingAdsState extends State<RotatingAds> {
  List<Map<String, dynamic>> ads = [];
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    loadAds();
    timer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (!mounted || ads.length < 2) return;
        setState(() => index = (index + 1) % ads.length);
      },
    );
  }

  Future<void> loadAds() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final result = await Supabase.instance.client
          .from('paid_ads')
          .select('id,business_name,image_url,target_url')
          .eq('placement', widget.placement)
          .eq('status', 'active')
          .eq('payment_status', 'paid')
          .lte('starts_at', now)
          .gt('expires_at', now);

      if (!mounted) return;
      setState(() {
        ads = List<Map<String, dynamic>>.from(result);
        index = 0;
      });
    } catch (e) {
      debugPrint('Rotating ads error: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[
      ...ads,
      if (kDebugMode && ads.isEmpty)
        {
          'id': 'demo-${widget.placement}',
          'business_name': 'BLiZ TV',
          'image_url': '',
          'target_url': 'https://bliztv.online',
        },
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    final ad = items[index % items.length];
    final name = ad['business_name']?.toString() ?? '';
    final image = ad['image_url']?.toString() ?? '';
    final url = Uri.tryParse(ad['target_url']?.toString() ?? '');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: InkWell(
        key: ValueKey(ad['id']),
        onTap: url?.scheme == 'https'
            ? () => launchUrl(url!, mode: LaunchMode.externalApplication)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102B4B), Color(0xFF17649A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF38BDF8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kDebugMode && ads.isEmpty
                    ? 'DEMO - Sponsored'
                    : 'Sponsored',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              if (image.startsWith('https://'))
                Image.network(
                  image,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.tv, color: Colors.white, size: 48),
                )
              else
                const Icon(Icons.tv, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visit website',
                style: TextStyle(color: Color(0xFFBAE6FD)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
