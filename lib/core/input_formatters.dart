import 'package:flutter/services.dart';

/// Sanitises a pasted phone number so it always ends up as the **last 10
/// digits**. Without this, pasting "+91 98765 43210" (or "098765 43210")
/// leaves "9198765432" after the 10-char limit — losing the last two digits.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 10) {
      // Drop a country code / trunk prefix when present…
      if (digits.startsWith('91')) {
        digits = digits.substring(2);
      } else if (digits.startsWith('0')) {
        digits = digits.substring(1);
      }
      // …then keep only the last 10 digits as a fallback.
      if (digits.length > 10) {
        digits = digits.substring(digits.length - 10);
      }
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
