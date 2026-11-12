import 'rotating_ads.dart';
import 'paid_ads_banner.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'create_listing_page.dart';
import 'create_paid_ad_page.dart';
import 'published_listings.dart';
import 'country_selector.dart';
import 'coffee_support.dart';
import 'listing_countries.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceHome extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final List<String> uiTexts;
  const MarketplaceHome({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.uiTexts,
  });
  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  int selected = -1;
  int refreshVersion = 0;
  String? selectedCountry;
  bool countryChosen = false;
  static const countryPreference = 'marketplace_country';

  @override
  void initState() {
    super.initState();
    restoreCountry();
  }

  Future<void> restoreCountry() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(countryPreference);
      if (mounted && !countryChosen && listingCountry(saved) != null) {
        setState(() => selectedCountry = saved);
      }
    } catch (_) {
      // Browsing remains available when local storage is unavailable.
    }
  }

  Future<void> chooseCountry(String? code) async {
    countryChosen = true;
    setState(() => selectedCountry = code);
    try {
      final preferences = await SharedPreferences.getInstance();
      if (code == null) {
        await preferences.remove(countryPreference);
      } else {
        await preferences.setString(countryPreference, code);
      }
    } catch (_) {
      // The current selection still works without persistence.
    }
  }

  Widget countrySelector() => CountrySelector(
    countryCode: selectedCountry,
    language: widget.language,
    onChanged: chooseCountry,
  );
  final search = TextEditingController();

  Future<void> openPaidAds() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePaidAdPage()),
    );
  }

  static const ids = [
    'rides',
    'jobs',
    'housing',
    'vehicles',
    'home_goods',
    'electronics',
    'services',
    'other',
  ];
  static const localizedNames = <String, List<String>>{
    'en': [
      'Rides',
      'Jobs',
      'Housing',
      'Vehicles',
      'Home goods',
      'Electronics',
      'Services',
      'Other',
    ],
    'mk': [
      'Превоз',
      'Работа',
      'Недвижности',
      'Автомобили',
      'За домот',
      'Електроника',
      'Услуги',
      'Останато',
    ],
    'sr': [
      'Prevoz',
      'Posao',
      'Nekretnine',
      'Automobili',
      'Za kuću',
      'Elektronika',
      'Usluge',
      'Ostalo',
    ],
    'bs': [
      'Prijevoz',
      'Posao',
      'Nekretnine',
      'Automobili',
      'Za kuću',
      'Elektronika',
      'Usluge',
      'Ostalo',
    ],
    'hr': [
      'Prijevoz',
      'Posao',
      'Nekretnine',
      'Automobili',
      'Za dom',
      'Elektronika',
      'Usluge',
      'Ostalo',
    ],
    'sq': [
      'Transport',
      'Punë',
      'Prona',
      'Automjete',
      'Për shtëpi',
      'Elektronikë',
      'Shërbime',
      'Të tjera',
    ],
    'me': [
      'Prevoz',
      'Posao',
      'Nekretnine',
      'Automobili',
      'Za kuću',
      'Elektronika',
      'Usluge',
      'Ostalo',
    ],
    'sl': [
      'Prevoz',
      'Delo',
      'Nepremičnine',
      'Avtomobili',
      'Za dom',
      'Elektronika',
      'Storitve',
      'Ostalo',
    ],
    'bg': [
      'Транспорт',
      'Работа',
      'Имоти',
      'Автомобили',
      'За дома',
      'Електроника',
      'Услуги',
      'Други',
    ],
    'el': [
      'ÎœÎµÏ„Î±Ï†Î¿ÏÎ­Ï‚',
      'Î•ÏÎ³Î±ÏƒÎ¯Î±',
      'Î‘ÎºÎ¯Î½Î·Ï„Î±',
      'Î‘Ï…Ï„Î¿ÎºÎ¯Î½Î·Ï„Î±',
      'Î“Î¹Î± Ï„Î¿ ÏƒÏ€Î¯Ï„Î¹',
      'Î—Î»ÎµÎºÏ„ÏÎ¿Î½Î¹ÎºÎ¬',
      'Î¥Ï€Î·ÏÎµÏƒÎ¯ÎµÏ‚',
      'Î†Î»Î»Î±',
    ],
    'xk': [
      'Transport',
      'Punë',
      'Prona',
      'Automjete',
      'Për shtëpi',
      'Elektronikë',
      'Shërbime',
      'Të tjera',
    ],
    'ro': [
      'Transport',
      'Locuri de muncă',
      'Imobiliare',
      'Automobile',
      'Pentru casă',
      'Electronice',
      'Servicii',
      'Altele',
    ],
  };
  static const subtitles = <String, List<String>>{
    'en': [
      'Rides • Logistics',
      'Vacancies • Employment',
      'Houses • Apartments',
      'Vehicles • Parts',
      'Furniture • Equipment',
      'Phones • Laptops',
      'Tradespeople • Help',
      'Other listings',
    ],
    'mk': [
      'Камиони • Логистика',
      'Огласи • Вработување',
      'Куќи • Станови',
      'Возила • Делови',
      'Мебел • Опрема',
      'Телефони • Лаптопи',
      'Мајстори • Помош',
      'Разни огласи',
    ],
    'sr': [
      'Kamioni • Logistika',
      'Oglasi • Zaposlenje',
      'Kuće • Stanovi',
      'Vozila • Delovi',
      'Nameštaj • Oprema',
      'Telefoni • Laptopi',
      'Majstori • Pomoć',
      'Razni oglasi',
    ],
    'bs': [
      'Kamioni • Logistika',
      'Poslovi • Zaposlenje',
      'Kuće • Stanovi',
      'Vozila • Dijelovi',
      'Namještaj • Oprema',
      'Telefoni • Laptopi',
      'Majstori • Pomoć',
      'Razni oglasi',
    ],
    'hr': [
      'Kamioni • Logistika',
      'Poslovi • Zaposlenje',
      'Kuće • Stanovi',
      'Vozila • Dijelovi',
      'Namještaj • Oprema',
      'Telefoni • Laptopi',
      'Majstori • Pomoć',
      'Razni oglasi',
    ],
    'sq': [
      'Kamionë • Logjistikë',
      'Punë • Punësim',
      'Shtëpi • Banesa',
      'Makina • Pjesë',
      'Mobilje • Pajisje',
      'Telefona • Laptopë',
      'Mjeshtër • Ndihmë',
      'Njoftime të tjera',
    ],
    'me': [
      'Kamioni • Logistika',
      'Poslovi • Zaposlenje',
      'Kuće • Stanovi',
      'Vozila • Djelovi',
      'Namještaj • Oprema',
      'Telefoni • Laptopi',
      'Majstori • Pomoć',
      'Razni oglasi',
    ],
    'sl': [
      'Tovornjaki • Logistika',
      'Delo • Zaposlitev',
      'Hiše • Stanovanja',
      'Vozila • Deli',
      'Pohištvo • Oprema',
      'Telefoni • Prenosniki',
      'Mojstri • Pomoč',
      'Razni oglasi',
    ],
    'bg': [
      'Камиони • Логистика',
      'Обяви • Заетост',
      'Къщи • Апартаменти',
      'Коли • Части',
      'Мебели • Оборудване',
      'Телефони • Лаптопи',
      'Майстори • Помощ',
      'Разни обяви',
    ],
    'el': [
      'Φορτηγά • Μεταφορές',
      'Θέσεις • Εργασία',
      'Σπίτια • Διαμερίσματα',
      'Οχήματα • Ανταλλακτικά',
      'Έπιπλα • Εξοπλισμός',
      'Κινητά • Laptop',
      'Τεχνίτες • Βοήθεια',
      'Άλλες αγγελίες',
    ],
    'xk': [
      'Kamionë • Logjistikë',
      'Punë • Punësim',
      'Shtëpi • Banesa',
      'Makina • Pjesë',
      'Mobilje • Pajisje',
      'Telefona • Laptopë',
      'Mjeshtër • Ndihmë',
      'Njoftime të tjera',
    ],
    'ro': [
      'Camioane • Logistică',
      'Locuri • Angajare',
      'Case • Apartamente',
      'Mașini • Piese',
      'Mobilă • Echipamente',
      'Telefoane • Laptopuri',
      'Meșteri • Ajutor',
      'AnunÈ›uri diverse',
    ],
  };
  static const icons = [
    Icons.local_shipping,
    Icons.engineering,
    Icons.home_work,
    Icons.directions_car,
    Icons.shopping_cart,
    Icons.laptop_mac,
    Icons.handyman,
    Icons.groups,
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AuthPage()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateListingPage(initialCountryCode: selectedCountry),
      ),
    );
    if (mounted) setState(() => refreshVersion++);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 900
        ? 4
        : w >= 560
        ? 3
        : 2;
    final labels = localizedNames[widget.language] ?? localizedNames['mk']!;
    final details = subtitles[widget.language] ?? subtitles['mk']!;
    final ui = widget.uiTexts;
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/hero_home.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xB3071A34), BlendMode.darken),
        ),
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ui[0],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ui[1],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC6D9EF),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFB8D8F4),
                    ),
                    hintText: ui[2],
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(search.clear),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w >= 900 ? 20 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    countrySelector(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: openPaidAds,
                        icon: const Icon(Icons.campaign_outlined),
                        label: Text(
                          widget.language == 'mk'
                              ? 'Рекламирај се · 9,99 € / 30 дена'
                              : 'Advertise · €9.99 / 30 days',
                        ),
                      ),
                    ),
                    if (w >= 560) const SizedBox(height: 8),
                    if (w >= 560)
                      Text(
                        CountryTexts.forLanguage(widget.language).hint,
                        style: const TextStyle(color: Color(0xFFE0EAF5)),
                      ),
                    const SizedBox(height: 18),

                    if (w >= 1100) ...[const SizedBox(height: 8)],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (w >= 1100) ...[
                          const SizedBox(
                            width: 180,
                            child: RotatingAds(placement: 'sidebar'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                ui[3],
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 18),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ids.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: w < 560 ? 2 : cols,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: w < 560 ? 145 : 170,
                                    ),
                                itemBuilder: (context, i) {
                                  final active = selected == i;
                                  return Material(
                                    color: const Color(0xFF102844),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: () => setState(
                                        () => selected = active ? -1 : i,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'assets/category_new_$i.png',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          border: Border.all(
                                            color: active
                                                ? const Color(0xFF22C6FF)
                                                : const Color(0xFF234A70),
                                            width: active ? 3 : 1,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x08000000),
                                                Color(0xE6001026),
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                icons[i],
                                                color: Colors.white,
                                                size: 23,
                                              ),
                                              const Spacer(),
                                              Text(
                                                labels[i],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                details[i],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFFE0EAF5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (w >= 1100) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 180,
                            child: RotatingAds(placement: 'sidebar'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const PaidAdsBanner(),
                    if (w < 1100) ...[
                      const SizedBox(height: 12),
                      const RotatingAds(placement: 'sidebar'),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w >= 900 ? 20 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 22),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected < 0 ? ui[8] : labels[selected],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (selected >= 0)
                          TextButton(
                            onPressed: () => setState(() => selected = -1),
                            child: Text(ui[11]),
                          ),
                        IconButton(
                          onPressed: () => setState(() => refreshVersion++),
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    PublishedListings(
                      key: ValueKey(refreshVersion),
                      selectedCategory: selected,
                      countryCode: selectedCountry,
                      language: widget.language,
                      search: search.text,
                      emptyMessage: selectedCountry != null
                          ? CountryTexts.forLanguage(widget.language).empty
                          : search.text.trim().isNotEmpty
                          ? '${ui[14]} “${search.text.trim()}”'
                          : selected < 0
                          ? ui[12]
                          : '${ui[13]} ${labels[selected]}.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: publish,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(ui[9]),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0879CD),
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: openPaidAds,
                      icon: const Icon(Icons.campaign_outlined),
                      label: Text(
                        widget.language == 'mk'
                            ? 'Рекламирај се · 9,99 € / 30 дена'
                            : 'Advertise · €9.99 / 30 days',
                      ),
                    ),
                    CoffeeSupport(language: widget.language),
                    const SizedBox(height: 32),
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
