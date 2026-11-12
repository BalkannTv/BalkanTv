class ListingCountry {
  const ListingCountry(this.code, this.flag, this.name, this.mkName);
  final String code;
  final String flag;
  final String name;
  final String mkName;

  String label(String language) => '$flag ${language == 'mk' ? mkName : name}';
}

// Listing locations are independent of the interface language.
const listingCountries = <ListingCountry>[
  ListingCountry('DE', '🇩🇪', 'Germany', 'Германија'),
  ListingCountry('AT', '🇦🇹', 'Austria', 'Австрија'),
  ListingCountry('CZ', '🇨🇿', 'Czechia', 'Чешка'),
  ListingCountry('SK', '🇸🇰', 'Slovakia', 'Словачка'),
  ListingCountry('NL', '🇳🇱', 'Netherlands', 'Холандија'),
  ListingCountry('BE', '🇧🇪', 'Belgium', 'Белгија'),
  ListingCountry('DK', '🇩🇰', 'Denmark', 'Данска'),
  ListingCountry('NO', '🇳🇴', 'Norway', 'Норвешка'),
  ListingCountry('SE', '🇸🇪', 'Sweden', 'Шведска'),
  ListingCountry('CH', '🇨🇭', 'Switzerland', 'Швајцарија'),
  ListingCountry('MK', '🇲🇰', 'North Macedonia', 'Македонија'),
  ListingCountry('RS', '🇷🇸', 'Serbia', 'Србија'),
  ListingCountry('BA', '🇧🇦', 'Bosnia and Herzegovina', 'Босна и Херцеговина'),
  ListingCountry('HR', '🇭🇷', 'Croatia', 'Хрватска'),
  ListingCountry('AL', '🇦🇱', 'Albania', 'Албанија'),
  ListingCountry('ME', '🇲🇪', 'Montenegro', 'Црна Гора'),
  ListingCountry('SI', '🇸🇮', 'Slovenia', 'Словенија'),
  ListingCountry('BG', '🇧🇬', 'Bulgaria', 'Бугарија'),
  ListingCountry('GR', '🇬🇷', 'Greece', 'Грција'),
  ListingCountry('XK', '🇽🇰', 'Kosovo', 'Косово'),
  ListingCountry('RO', '🇷🇴', 'Romania', 'Романија'),
  ListingCountry('IT', '🇮🇹', 'Italy', 'Италија'),
  ListingCountry('FR', '🇫🇷', 'France', 'Франција'),
  ListingCountry('GB', '🇬🇧', 'United Kingdom', 'Обединето Кралство'),
  ListingCountry('OTHER', '🌍', 'Other', 'Друга држава'),
];

ListingCountry? listingCountry(String? code) {
  for (final country in listingCountries) {
    if (country.code == code) return country;
  }
  return null;
}

String listingCountryFilter(String code) {
  if (listingCountry(code) == null) throw ArgumentError.value(code, 'country');
  return 'country_code.eq.$code,'
      'and(category.eq.rides,or(origin_country_code.eq.$code,'
      'destination_country_code.eq.$code))';
}

class CountryTexts {
  const CountryTexts(this.choose, this.all, this.hint, this.empty);
  final String choose;
  final String all;
  final String hint;
  final String empty;

  static CountryTexts forLanguage(String language) => switch (language) {
    'mk' => const CountryTexts(
      'Избери држава',
      'Сите држави',
      'Работа, превоз, станови и услуги во избраната држава.',
      'Нема огласи за избраната држава и филтри.',
    ),
    'sr' || 'bs' || 'hr' || 'me' => const CountryTexts(
      'Izaberi državu',
      'Sve države',
      'Posao, prevoz, stanovi i usluge u izabranoj državi.',
      'Nema oglasa za izabranu državu i filtere.',
    ),
    'sl' => const CountryTexts(
      'Izberi državo',
      'Vse države',
      'Delo, prevoz, stanovanja in storitve v izbrani državi.',
      'Za izbrano državo in filtre ni oglasov.',
    ),
    'bg' => const CountryTexts(
      'Избери държава',
      'Всички държави',
      'Работа, транспорт, имоти и услуги в избраната държава.',
      'Няма обяви за избраната държава и филтри.',
    ),
    'sq' || 'xk' => const CountryTexts(
      'Zgjidh shtetin',
      'Të gjitha shtetet',
      'Punë, transport, banesa dhe shërbime në shtetin e zgjedhur.',
      'Nuk ka njoftime për shtetin dhe filtrat e zgjedhur.',
    ),
    'ro' => const CountryTexts(
      'Alege țara',
      'Toate țările',
      'Locuri de muncă, transport, locuințe și servicii în țara aleasă.',
      'Nu există anunțuri pentru țara și filtrele selectate.',
    ),
    'el' => const CountryTexts(
      'Επιλέξτε χώρα',
      'Όλες οι χώρες',
      'Εργασία, μεταφορές, κατοικίες και υπηρεσίες στην επιλεγμένη χώρα.',
      'Δεν υπάρχουν αγγελίες για τη χώρα και τα φίλτρα που επιλέξατε.',
    ),
    _ => const CountryTexts(
      'Choose country',
      'All countries',
      'Jobs, rides, housing and services in your selected country.',
      'No listings match the selected country and filters.',
    ),
  };
}
