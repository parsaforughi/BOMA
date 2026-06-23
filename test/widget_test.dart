import 'package:flutter_test/flutter_test.dart';
import 'package:boma/utils/farsi_utils.dart';

void main() {
  group('Farsi Utils', () {
    test('toFarsiNumber converts digits correctly', () {
      expect(toFarsiNumber(123), '۱۲۳');
      expect(toFarsiNumber('09121234567'), '۰۹۱۲۱۲۳۴۵۶۷');
      expect(toFarsiNumber(0), '۰');
    });

    test('toFarsiPrice formats correctly', () {
      expect(toFarsiPrice(49000), '۴۹,۰۰۰ تومان');
      expect(toFarsiPrice(119000), '۱۱۹,۰۰۰ تومان');
    });

    test('isValidIranianPhone validates correctly', () {
      expect(isValidIranianPhone('09121234567'), true);
      expect(isValidIranianPhone('09001234567'), true);
      expect(isValidIranianPhone('1234567890'), false);
      expect(isValidIranianPhone('0912123456'), false); // too short
      expect(isValidIranianPhone('091212345678'), false); // too long
    });

    test('toLatiNumber converts Farsi digits back', () {
      expect(toLatiNumber('۰۹۱۲۱۲۳۴۵۶۷'), '09121234567');
      expect(toLatiNumber('۱۲۳'), '123');
    });
  });
}
