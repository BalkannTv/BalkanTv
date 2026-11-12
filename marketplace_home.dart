import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'create_listing_page.dart';
import 'published_listings.dart';

class MarketplaceHome extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;
  const MarketplaceHome({super.key, required this.language, required this.onLanguageChanged});
  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  int selected = -1;
  int refreshVersion = 0;
  final search = TextEditingController();

  static const ids = ['rides','jobs','housing','vehicles','home_goods','electronics','services','other'];
  static const names = ['Transport','Jobs','Housing','Vehicles','Home goods','Electronics','Services','Other'];
  static const subtitles = [
    'Trucks • Drivers • Logistics', 'Vacancies • Seasonal work',
    'Sale • Rent • Apartments', 'Used • New • Parts',
    'Furniture • Equipment', 'Phones • Laptops • IT',
    'Trades • Beauty • More', 'Travel • Education • More'
  ];
  static const icons = [Icons.local_shipping, Icons.engineering, Icons.home_work,
    Icons.directions_car, Icons.shopping_cart, Icons.laptop_mac, Icons.handyman, Icons.groups];
  static const colors = [Color(0xFF0078C7),Color(0xFFC27A19),Color(0xFF19834C),
    Color(0xFFC73D48),Color(0xFF8C40CB),Color(0xFF155DCE),Color(0xFFB1388C),Color(0xFF0094AE)];
  static const flags = [
    ('🇲🇰','mk'),('🇷🇸','sr'),('🇧🇦','bs'),('🇭🇷','hr'),('🇸🇮','sl'),
    ('🇲🇪','me'),('🇧🇬','bg'),('🇷🇴','ro'),('🇦🇱','sq'),('🇬🇷','el'),('🇽🇰','xk')
  ];

  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> publish() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateListingPage()));
    if (mounted) setState(() => refreshVersion++);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 900 ? 4 : w >= 560 ? 3 : 2;
    final t = widget.language == 'mk';
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF103D68), Color(0xFF071A34), Color(0xFF09182C)],
      )),
      child: ListView(children: [
        // The hero is decorative. Every category below is a real Flutter button.
        Stack(children: [
          SizedBox(width: double.infinity, height: w < 620 ? 175 : 270,
            child: Image.asset('assets/balkan_hero.jpg', fit: BoxFit.cover,
              alignment: Alignment.topCenter)),
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: 70, decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF103D68)]))))
        ]),
        Padding(padding: EdgeInsets.symmetric(horizontal: w >= 900 ? 30 : 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: ids.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12,
                mainAxisExtent: w >= 900 ? 126 : w >= 560 ? 120 : 110),
              itemBuilder: (context, i) {
                final active = selected == i;
                return Material(color: Colors.transparent, child: InkWell(
                  onTap: () => setState(() => selected = active ? -1 : i),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: active ? Colors.white : colors[i], width: active ? 3 : 1.5),
                      boxShadow: [BoxShadow(color: colors[i].withValues(alpha: .30), blurRadius: 6)],
                      image: DecorationImage(image: AssetImage('assets/category_$i.jpg'), fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(colors[i].withValues(alpha: .24), BlendMode.srcOver))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(icons[i], color: Colors.white, size: w < 620 ? 23 : 28),
                      const Spacer(),
                      Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                          fontSize: w < 620 ? 15 : 18)),
                      const SizedBox(height: 2),
                      Text(subtitles[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                ));
              },
            ),
            const SizedBox(height: 22),

            TextField(controller: search, onChanged: (_) => setState(() {}),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search),
                hintText: t ? 'Пребарај огласи...' : widget.language == 'en' ? 'Search listings...' : 'Pretraži oglase...',
                filled: true, fillColor: const Color(0xFF19395A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(selected < 0 ? (t ? 'Најнови огласи' : widget.language == 'en' ? 'Latest listings' : 'Najnoviji oglasi') : names[selected],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              if (selected >= 0) TextButton(onPressed: () => setState(() => selected = -1),
                child: Text(t ? 'Сите' : 'Sve')),
              IconButton(onPressed: () => setState(() => refreshVersion++),
                tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
            ]),
            PublishedListings(key: ValueKey(refreshVersion), selectedCategory: selected,
              search: search.text, emptyMessage: t ? 'Нема огласи во оваа категорија.' : 'Nema oglasa u kategoriji.'),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: publish, icon: const Icon(Icons.add_circle_outline),
              label: Text(t ? 'Објави оглас' : 'Objavi oglas'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0879CD),
                padding: const EdgeInsets.all(18))),
            const SizedBox(height: 32),
          ])),
      ]),
    );
  }
}
