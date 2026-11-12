import 'package:flutter/material.dart';

import 'listing_countries.dart';

class CountrySelector extends StatelessWidget {
  const CountrySelector({
    super.key,
    required this.countryCode,
    required this.language,
    required this.onChanged,
  });
  final String? countryCode;
  final String language;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final texts = CountryTexts.forLanguage(language);
    return DropdownButtonFormField<String>(
      key: ValueKey('$countryCode-$language'),
      initialValue: countryCode ?? '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: texts.choose,
        prefixIcon: const Icon(Icons.public),
        filled: true,
        fillColor: const Color(0xFF19395A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text('🌍 ${texts.all}')),
        ...listingCountries.map(
          (country) => DropdownMenuItem(
            value: country.code,
            child: Text(
              country.label(language),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) => onChanged(value == '' ? null : value),
    );
  }
}
