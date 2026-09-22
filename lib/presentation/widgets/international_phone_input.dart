import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/phone_number_utils.dart';
import '../../core/theme/app_palette.dart';

class InternationalPhoneInput extends StatelessWidget {
  const InternationalPhoneInput({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final CountryPhoneOption selectedCountry;
  final ValueChanged<CountryPhoneOption> onCountryChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: _CountrySelector(
              selectedCountry: selectedCountry,
              enabled: enabled,
              onChanged: onCountryChanged,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : context.palette.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            errorText: hasError ? errorText : null,
          ),
        ),
      ],
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({
    required this.selectedCountry,
    required this.enabled,
    required this.onChanged,
  });

  final CountryPhoneOption selectedCountry;
  final bool enabled;
  final ValueChanged<CountryPhoneOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 6),
      padding: const EdgeInsetsDirectional.only(start: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: context.palette.border),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CountryPhoneOption>(
          value: selectedCountry,
          isDense: true,
          onChanged: enabled
              ? (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                }
              : null,
          items: PhoneNumberUtils.supportedCountries
              .map(
                (country) => DropdownMenuItem<CountryPhoneOption>(
                  value: country,
                  child: Text(
                    '${country.isoCode} ${country.dialCode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
