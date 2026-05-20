class CountryPhoneOption {
  const CountryPhoneOption({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    this.trunkPrefix,
  });

  final String isoCode;
  final String name;
  final String dialCode;
  final String? trunkPrefix;

  String get dialCodeDigits => dialCode.replaceFirst('+', '');
}

class PhoneNormalizationResult {
  const PhoneNormalizationResult({
    required this.rawInput,
    required this.normalizedPhone,
    required this.isValid,
  });

  final String rawInput;
  final String normalizedPhone;
  final bool isValid;
}

class PhoneNumberUtils {
  static const List<CountryPhoneOption> supportedCountries = [
    CountryPhoneOption(
      isoCode: 'EG',
      name: 'Egypt',
      dialCode: '+20',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'SA',
      name: 'Saudi Arabia',
      dialCode: '+966',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'AE',
      name: 'United Arab Emirates',
      dialCode: '+971',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'KW',
      name: 'Kuwait',
      dialCode: '+965',
    ),
    CountryPhoneOption(
      isoCode: 'QA',
      name: 'Qatar',
      dialCode: '+974',
    ),
    CountryPhoneOption(
      isoCode: 'BH',
      name: 'Bahrain',
      dialCode: '+973',
    ),
    CountryPhoneOption(
      isoCode: 'OM',
      name: 'Oman',
      dialCode: '+968',
    ),
    CountryPhoneOption(
      isoCode: 'JO',
      name: 'Jordan',
      dialCode: '+962',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'LB',
      name: 'Lebanon',
      dialCode: '+961',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'US',
      name: 'United States',
      dialCode: '+1',
      trunkPrefix: '1',
    ),
    CountryPhoneOption(
      isoCode: 'CA',
      name: 'Canada',
      dialCode: '+1',
      trunkPrefix: '1',
    ),
    CountryPhoneOption(
      isoCode: 'GB',
      name: 'United Kingdom',
      dialCode: '+44',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'DE',
      name: 'Germany',
      dialCode: '+49',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'FR',
      name: 'France',
      dialCode: '+33',
      trunkPrefix: '0',
    ),
    CountryPhoneOption(
      isoCode: 'IN',
      name: 'India',
      dialCode: '+91',
      trunkPrefix: '0',
    ),
  ];

  static const CountryPhoneOption defaultCountry = CountryPhoneOption(
    isoCode: 'EG',
    name: 'Egypt',
    dialCode: '+20',
    trunkPrefix: '0',
  );

  static bool looksLikeEmail(String value) {
    return value.contains('@');
  }

  static PhoneNormalizationResult normalize({
    required String rawInput,
    required CountryPhoneOption country,
  }) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const PhoneNormalizationResult(
        rawInput: '',
        normalizedPhone: '',
        isValid: false,
      );
    }

    var sanitized = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (sanitized.startsWith('00')) {
      sanitized = '+${sanitized.substring(2)}';
    }

    String normalizedPhone;
    if (sanitized.startsWith('+')) {
      final digits = sanitized.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      normalizedPhone = '+$digits';
    } else {
      var localDigits = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
      if (localDigits.startsWith(country.dialCodeDigits)) {
        normalizedPhone = '+$localDigits';
      } else {
        final trunkPrefix = country.trunkPrefix;
        if (trunkPrefix != null &&
            localDigits.startsWith(trunkPrefix) &&
            localDigits.length > trunkPrefix.length) {
          localDigits = localDigits.substring(trunkPrefix.length);
        }
        normalizedPhone = '+${country.dialCodeDigits}$localDigits';
      }
    }

    return PhoneNormalizationResult(
      rawInput: trimmed,
      normalizedPhone: normalizedPhone,
      isValid: RegExp(r'^\+\d{8,15}$').hasMatch(normalizedPhone),
    );
  }
}
