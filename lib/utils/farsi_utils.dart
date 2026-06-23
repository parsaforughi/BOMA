/// Converts Latin digits to Farsi digits
String toFarsiNumber(dynamic input) {
  if (input == null) return '';
  const farsiDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return input.toString().replaceAllMapped(
    RegExp(r'\d'),
    (match) => farsiDigits[int.parse(match.group(0)!)],
  );
}

/// Formats a number as Farsi price with Toman suffix
String toFarsiPrice(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );
  return '${toFarsiNumber(formatted)} تومان';
}

/// Validates Iranian phone number format
bool isValidIranianPhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
  return RegExp(r'^09\d{9}$').hasMatch(cleaned);
}

/// Converts Farsi digits to Latin digits
String toLatiNumber(String input) {
  const farsiDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  String result = input;
  for (int i = 0; i < farsiDigits.length; i++) {
    result = result.replaceAll(farsiDigits[i], i.toString());
  }
  return result;
}
