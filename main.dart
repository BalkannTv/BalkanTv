import 'marketplace_home.dart';
import 'radio_player.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'admin_service.dart';
import 'admin_panel.dart';
import 'auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://urzkpettpgghihrxguhc.supabase.co',
    publishableKey: 'sb_publishable_L-iouIXmCkazpdCG3X191w_TjGHsk3s',
  );

  runApp(const BalkanConnectApp());
}

const bg = Color(0xFF0B1830);
const panel = Color(0xFF182C4B);
const accent = Color(0xFF38BDF8);

class Country {
  final String flag;
  final String name;
  final String code;

  const Country(this.flag, this.name, this.code);
}

const countries = [
  Country('🇲🇰', 'Македонија', 'mk'),
  Country('🇷🇸', 'Srbija', 'sr'),
  Country('🇧🇦', 'Bosna i Hercegovina', 'bs'),
  Country('🇭🇷', 'Hrvatska', 'hr'),
  Country('🇦🇱', 'Shqipëria', 'sq'),
  Country('🇲🇪', 'Crna Gora', 'me'),
  Country('🇸🇮', 'Slovenija', 'sl'),
  Country('🇧🇬', 'България', 'bg'),
  Country('🇬🇷', 'Ελλάδα', 'el'),
  Country('🇽🇰', 'Kosova', 'xk'),
  Country('🇷🇴', 'România', 'ro'),
];

// Translation order:
// title, subtitle, search, categories, jobs, transport,
// housing, services, latest, publish, login, all,
// empty, emptyCategory, noResults, soon, notice,
// chooseLanguage, selectedLanguage
const translations = <String, List<String>>{
  'en': [
    'Your Balkans. Wherever you are.',
    'Jobs, transport, housing and services — all in one place.',
    'Search listings...',
    'Categories', 'Jobs', 'Transport', 'Housing', 'Services',
    'Latest listings', 'Post listing', 'Sign in', 'All',
    'No listings yet.', 'No listings in category', 'No results for',
    'Coming soon', 'New listings will appear here soon.',
    'Choose language', 'Selected language',
  ],

  'mk': [
    'Твојот Балкан. Секаде со тебе.',
    'Работа, превоз, станови и услуги — на едно место.',
    'Пребарај огласи...',
    'Категории', 'Работа', 'Превоз', 'Станови', 'Услуги',
    'Најнови огласи', 'Објави оглас', 'Најава', 'Сите',
    'Сè уште нема објавени огласи.',
    'Сè уште нема огласи во категоријата',
    'Нема резултати за',
    'наскоро достапно',
    'Наскоро ќе ги поврземе вистинските огласи.',
    'Избери јазик',
    'Избран јазик',
  ],
  'sr': [
    'Tvoj Balkan. Svuda sa tobom.',
    'Posao, prevoz, stanovi i usluge — na jednom mestu.',
    'Pretraži oglase...',
    'Kategorije', 'Posao', 'Prevoz', 'Stanovi', 'Usluge',
    'Najnoviji oglasi', 'Objavi oglas', 'Prijava', 'Sve',
    'Još nema objavljenih oglasa.',
    'Još nema oglasa u kategoriji',
    'Nema rezultata za',
    'uskoro dostupno',
    'Uskoro stižu pravi oglasi.',
    'Izaberi jezik',
    'Izabrani jezik',
  ],
  'bs': [
    'Tvoj Balkan. Svuda s tobom.',
    'Posao, prijevoz, stanovi i usluge — na jednom mjestu.',
    'Pretraži oglase...',
    'Kategorije', 'Posao', 'Prijevoz', 'Stanovi', 'Usluge',
    'Najnoviji oglasi', 'Objavi oglas', 'Prijava', 'Sve',
    'Još nema objavljenih oglasa.',
    'Još nema oglasa u kategoriji',
    'Nema rezultata za',
    'uskoro dostupno',
    'Uskoro stižu pravi oglasi.',
    'Izaberi jezik',
    'Izabrani jezik',
  ],
  'hr': [
    'Tvoj Balkan. Svugdje s tobom.',
    'Posao, prijevoz, stanovi i usluge — na jednom mjestu.',
    'Pretraži oglase...',
    'Kategorije', 'Posao', 'Prijevoz', 'Stanovi', 'Usluge',
    'Najnoviji oglasi', 'Objavi oglas', 'Prijava', 'Sve',
    'Još nema objavljenih oglasa.',
    'Još nema oglasa u kategoriji',
    'Nema rezultata za',
    'uskoro dostupno',
    'Uskoro stižu pravi oglasi.',
    'Odaberi jezik',
    'Odabrani jezik',
  ],
  'sq': [
    'Ballkani yt. Kudo me ty.',
    'Punë, transport, banesa dhe shërbime — në një vend.',
    'Kërko njoftime...',
    'Kategoritë', 'Punë', 'Transport', 'Banesa', 'Shërbime',
    'Njoftimet e fundit', 'Publiko njoftim', 'Hyrje', 'Të gjitha',
    'Ende nuk ka njoftime të publikuara.',
    'Ende nuk ka njoftime në kategorinë',
    'Nuk ka rezultate për',
    'së shpejti',
    'Së shpejti do të shfaqen njoftimet reale.',
    'Zgjidh gjuhën',
    'Gjuha e zgjedhur',
  ],
  'me': [
    'Tvoj Balkan. Svuda sa tobom.',
    'Posao, prevoz, stanovi i usluge — na jednom mjestu.',
    'Pretraži oglase...',
    'Kategorije', 'Posao', 'Prevoz', 'Stanovi', 'Usluge',
    'Najnoviji oglasi', 'Objavi oglas', 'Prijava', 'Sve',
    'Još nema objavljenih oglasa.',
    'Još nema oglasa u kategoriji',
    'Nema rezultata za',
    'uskoro dostupno',
    'Uskoro stižu pravi oglasi.',
    'Izaberi jezik',
    'Izabrani jezik',
  ],
  'sl': [
    'Tvoj Balkan. Vedno s teboj.',
    'Delo, prevoz, stanovanja in storitve — na enem mestu.',
    'Išči oglase...',
    'Kategorije', 'Delo', 'Prevoz', 'Stanovanja', 'Storitve',
    'Najnovejši oglasi', 'Objavi oglas', 'Prijava', 'Vse',
    'Objavljenih oglasov še ni.',
    'V kategoriji še ni oglasov',
    'Ni rezultatov za',
    'kmalu na voljo',
    'Kmalu bodo na voljo pravi oglasi.',
    'Izberi jezik',
    'Izbrani jezik',
  ],
  'bg': [
    'Твоите Балкани. Навсякъде с теб.',
    'Работа, транспорт, жилища и услуги — на едно място.',
    'Търси обяви...',
    'Категории', 'Работа', 'Транспорт', 'Жилища', 'Услуги',
    'Най-нови обяви', 'Публикувай обява', 'Вход', 'Всички',
    'Все още няма публикувани обяви.',
    'Все още няма обяви в категория',
    'Няма резултати за',
    'очаквайте скоро',
    'Скоро ще има реални обяви.',
    'Избери език',
    'Избран език',
  ],
  'el': [
    'Τα Βαλκάνιά σου. Παντού μαζί σου.',
    'Εργασία, μεταφορές, κατοικίες και υπηρεσίες σε ένα μέρος.',
    'Αναζήτηση αγγελιών...',
    'Κατηγορίες', 'Εργασία', 'Μεταφορές', 'Κατοικίες', 'Υπηρεσίες',
    'Νέες αγγελίες', 'Δημοσίευση αγγελίας', 'Σύνδεση', 'Όλα',
    'Δεν υπάρχουν ακόμη αγγελίες.',
    'Δεν υπάρχουν αγγελίες στην κατηγορία',
    'Δεν βρέθηκαν αποτελέσματα για',
    'σύντομα διαθέσιμο',
    'Σύντομα θα εμφανιστούν πραγματικές αγγελίες.',
    'Επιλογή γλώσσας',
    'Επιλεγμένη γλώσσα',
  ],
  'xk': [
    'Ballkani yt. Kudo me ty.',
    'Punë, transport, banesa dhe shërbime — në një vend.',
    'Kërko njoftime...',
    'Kategoritë', 'Punë', 'Transport', 'Banesa', 'Shërbime',
    'Njoftimet e fundit', 'Publiko njoftim', 'Hyrje', 'Të gjitha',
    'Ende nuk ka njoftime të publikuara.',
    'Ende nuk ka njoftime në kategorinë',
    'Nuk ka rezultate për',
    'së shpejti',
    'Së shpejti do të shfaqen njoftimet reale.',
    'Zgjidh gjuhën',
    'Gjuha e zgjedhur',
  ],
  'ro': [
    'Balcanii tăi. Oriunde cu tine.',
    'Locuri de muncă, transport, locuințe și servicii.',
    'Caută anunțuri...',
    'Categorii', 'Locuri de muncă', 'Transport', 'Locuințe',
    'Servicii', 'Cele mai noi anunțuri', 'Publică anunț',
    'Autentificare', 'Toate',
    'Nu există încă anunțuri publicate.',
    'Nu există încă anunțuri în categoria',
    'Nu există rezultate pentru',
    'disponibil în curând',
    'În curând vor apărea anunțuri reale.',
    'Alege limba',
    'Limba selectată',
  ],
};

class BalkanConnectApp extends StatefulWidget {
  const BalkanConnectApp({super.key});

  @override
  State<BalkanConnectApp> createState() => _BalkanConnectAppState();
}

class _BalkanConnectAppState extends State<BalkanConnectApp> {
  String language = 'en';
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString('bc_language');
      if (mounted && saved != null && translations.containsKey(saved)) setState(() => language = saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balkan Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: bg,
        ),
        scaffoldBackgroundColor: bg,
      ),
      home: HomePage(
        language: language,
        onLanguageChanged: (code) {
          setState(() => language = code);
          SharedPreferences.getInstance().then((prefs) => prefs.setString('bc_language', code));
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;

  const HomePage({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _flagFor(String code) => const {'en':'🇬🇧','mk':'🇲🇰','sr':'🇷🇸','bs':'🇧🇦','hr':'🇭🇷','sl':'🇸🇮','me':'🇲🇪','bg':'🇧🇬','ro':'🇷🇴','sq':'🇦🇱','el':'🇬🇷','xk':'🇽🇰'}[code] ?? '🌐';
  String t(int index) => translations[widget.language]![index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, color: accent),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Balkan Connect',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Language / Јазик',
            initialValue: widget.language,
            onSelected: widget.onLanguageChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
              PopupMenuItem(value: 'mk', child: Text('🇲🇰 Македонски')),
              PopupMenuItem(value: 'sr', child: Text('🇷🇸 Srpski')),
              PopupMenuItem(value: 'bs', child: Text('🇧🇦 Bosanski')),
              PopupMenuItem(value: 'hr', child: Text('🇭🇷 Hrvatski')),
              PopupMenuItem(value: 'sl', child: Text('🇸🇮 Slovenščina')),
              PopupMenuItem(value: 'me', child: Text('🇲🇪 Crnogorski')),
              PopupMenuItem(value: 'bg', child: Text('🇧🇬 Български')),
              PopupMenuItem(value: 'ro', child: Text('🇷🇴 Română')),
              PopupMenuItem(value: 'sq', child: Text('🇦🇱 Shqip')),
              PopupMenuItem(value: 'el', child: Text('🇬🇷 Ελληνικά')),
              PopupMenuItem(value: 'xk', child: Text('🇽🇰 Shqip (Kosovë)')),
            ],
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(_flagFor(widget.language) + ' ' + widget.language.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)))),
          ),
          FutureBuilder<bool>(
            future: AdminService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client
                    .from('listings')
                    .select('id')
                    .eq('status', 'pending'),
                builder: (context, pendingSnapshot) {
                  final count = pendingSnapshot.data?.length ?? 0;

                  return IconButton(
                    tooltip: count > 0
                        ? 'Admin Panel - $count pending'
                        : 'Admin Panel',
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xFF38BDF8),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -11,
                            top: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 19,
                                minHeight: 19,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminPanelPage(),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() {});
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: t(10),
            onPressed: () async {
              final auth = Supabase.instance.client.auth;
              final user = auth.currentUser;

              if (user == null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AuthPage(),
                  ),
                );
                if (mounted) setState(() {});
              } else {
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Balkan Connect - Profile'),
                    content: Text('Email: ${user.email ?? ""}'),
                    actions: [
          TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await auth.signOut();
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (mounted) setState(() {});
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: MarketplaceHome(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      bottomNavigationBar: const BalkanRadioBar(),
    );
  }
}












