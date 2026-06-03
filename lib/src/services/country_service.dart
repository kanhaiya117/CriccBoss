import 'dart:ui';

class CountryService {
  String detectCountryTeam() {
    final country = PlatformDispatcher.instance.locale.countryCode
        ?.toUpperCase();
    return switch (country) {
      'IN' => 'India',
      'AU' => 'Australia',
      'GB' => 'England',
      'PK' => 'Pakistan',
      'NZ' => 'New Zealand',
      'ZA' => 'South Africa',
      _ => 'India',
    };
  }
}
