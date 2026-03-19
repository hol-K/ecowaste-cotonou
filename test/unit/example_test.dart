import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Tests Examples', () {
    test('Basic math operations', () {
      expect(2 + 2, equals(4));
      expect(5 - 3, equals(2));
      expect(3 * 4, equals(12));
      expect(10 / 2, equals(5));
    });

    test('String operations', () {
      final message = 'EcoWaste Cotonou';
      expect(message, isNotEmpty);
      expect(message.contains('EcoWaste'), isTrue);
      expect(message.length, greaterThan(0));
    });

    test('List operations', () {
      final items = [1, 2, 3, 4, 5];
      expect(items.length, equals(5));
      expect(items.contains(3), isTrue);
      expect(items.isEmpty, isFalse);
    });

    test('Map operations', () {
      final map = {'name': 'EcoWaste', 'version': '1.0.0'};
      expect(map.containsKey('name'), isTrue);
      expect(map['name'], equals('EcoWaste'));
      expect(map.length, equals(2));
    });
  });
}
