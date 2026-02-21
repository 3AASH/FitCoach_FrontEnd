import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Test', () {
    test('1 + 1 should equal 2', () {
      expect(1 + 1, 2);
    });

    test('String concatenation works', () {
      expect('Hello' + ' ' + 'World', 'Hello World');
    });

    test('List operations work', () {
      final list = [1, 2, 3];
      expect(list.length, 3);
      expect(list.first, 1);
      expect(list.last, 3);
    });
  });
}
