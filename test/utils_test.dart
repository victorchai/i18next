import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/utils.dart';

void main() {
  group('evaluate', () {
    const locale = Locale('any');

    final level2 = <Object, Object>{
      'key': 'Second level leaf',
    };
    final level1 = <Object, Object>{
      'key': 'First level leaf',
      'nested': level2,
    };
    final data = <Object, Object>{
      'key': 'Zero level leaf',
      locale: level1,
    };

    test('given null path', () {
      expect(() => evaluate(null, data), throwsNoSuchMethodError);
    });

    test('given empty path', () {
      expect(evaluate([], data), data);
    });

    test('given a non matching path', () {
      expect(evaluate(['somewhere'], data), isNull);
      expect(evaluate([null], data), isNull);
    });

    test('given leaf matching path', () {
      expect(evaluate(['key'], data), 'Zero level leaf');
      expect(evaluate([locale, 'key'], data), 'First level leaf');
      expect(evaluate([locale, 'nested', 'key'], data), 'Second level leaf');
    });

    test('given under matching path', () {
      expect(evaluate([locale], data), level1);
      expect(evaluate([locale, 'nested'], data), level2);
    });

    test('given over matching path', () {
      expect(evaluate(['key', 'another'], data), isNull);
      expect(evaluate([locale, 'key', 'another'], data), isNull);
      expect(evaluate([locale, 'nested', 'key', 'another'], data), isNull);
    });
  });
}
