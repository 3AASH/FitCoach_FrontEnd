import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/core/utils/error_message.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';

/// `friendlyError` is the one place that decides whether a user sees a
/// translated sentence or a raw exception. The failure it guards against is
/// silent: a mapping that stops matching just falls through to the raw string,
/// which still renders -- only as `SocketException: Failed host lookup`, in
/// English, inside an Arabic app.
///
/// Key/language parity is already held by `i18n_guard_test.dart`, so this only
/// covers the classification.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LanguageProvider lang;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    lang = LanguageProvider();
    // The provider defaults to Arabic; pin English so the expectations below
    // can name the strings directly.
    await lang.setLanguage('en');
  });

  String en(String key) => LanguageProvider.textFor(false, key);

  group('transport failures are classified', () {
    test('socket failures read as offline', () {
      expect(
        friendlyError(lang, "SocketException: Failed host lookup: 'api.x.com'"),
        en('error_offline'),
      );
      expect(
        friendlyError(lang, 'DioException [connection error]: refused'),
        en('error_offline'),
      );
    });

    test('timeouts read as timeout', () {
      expect(
        friendlyError(lang, 'DioException [receive timeout]'),
        en('error_timeout'),
      );
    });

    test('401 reads as an expired session', () {
      expect(
        friendlyError(lang, 'Exception: 401 Unauthorized'),
        en('error_session_expired'),
      );
    });

    test('5xx reads as a server problem', () {
      expect(
        friendlyError(lang, 'Http status error [500]'),
        en('error_server'),
      );
    });
  });

  group('messages worth showing survive; noise does not', () {
    test('a server message written for users survives', () {
      expect(friendlyError(lang, 'Exception: Card declined'), 'Card declined');
    });

    test('framework noise falls back to generic', () {
      expect(
        friendlyError(lang, "type 'Null' is not a subtype of type 'String'"),
        en('error_generic'),
      );
      expect(
        friendlyError(lang, 'Exception: DioError [bad response]: #0 main'),
        en('error_generic'),
      );
    });

    test('null and blank fall back to generic', () {
      expect(friendlyError(lang, null), en('error_generic'));
      expect(friendlyError(lang, '   '), en('error_generic'));
    });
  });

  test('classification follows the active language', () async {
    await lang.setLanguage('ar');
    expect(
      friendlyError(lang, 'SocketException: Failed host lookup'),
      LanguageProvider.textFor(true, 'error_offline'),
    );
  });
}
