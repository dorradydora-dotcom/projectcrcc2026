import 'package:flutter_test/flutter_test.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

void main() {
  group('validInput Tests', () {
    test('Username validation - invalid username', () {
      expect(validInput('a', 3, 10, 'username'), 'not valid username');
    });

    test('Username validation - valid username', () {
      // GetUtils.isUsername is somewhat restrictive in GetX, usually requiring alphanumeric
      expect(validInput('user123', 3, 20, 'username'), null);
    });

    test('Password validation - too short', () {
      expect(validInput('123456', 7, 32, 'password'), "can't be less than 7");
    });

    test('Password validation - too long', () {
      expect(validInput('a' * 33, 7, 32, 'password'), "can't be more than 32");
    });

    test('Password validation - valid', () {
      expect(validInput('validpassword', 7, 32, 'password'), null);
    });

    test('Phone validation - invalid', () {
      expect(validInput('123', 10, 15, 'phone'), 'not valid phone');
    });

    test('Generic validation - too short', () {
      expect(validInput('ab', 3, 10, 'other'), "can't be less than 3");
    });

    test('Generic validation - too long', () {
      expect(
          validInput('abcdefghijk', 3, 10, 'other'), "can't be more than 10");
    });

    test('Generic validation - valid', () {
      expect(validInput('abcde', 3, 10, 'other'), null);
    });
  });

  group('AppLogger Tests', () {
    test('AppLogger methods run without error', () {
      // These primarily use debugPrint, so we just ensure they don't crash
      AppLogger.logInfo('Test Info');
      AppLogger.logSuccess('Test Success');
      AppLogger.logWarning('Test Warning');
      AppLogger.logError('Test Error');
    });
  });
}
