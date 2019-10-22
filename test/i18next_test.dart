import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18next/i18next.dart';

void main() {
  const locale = Locale('en');
  I18Next i18next;

  tearDown(() {
    i18next = null;
  });

  void given(
    Map<String, Object> data, {
    ArgumentFormatter formatter,
  }) {
    i18next = I18Next(
      locale,
      (namespace, locale) => data,
      options: I18NextOptions(formatter: formatter),
    );
  }

  group('given named namespaces', () {
    setUp(() {
      i18next = I18Next(
        locale,
        (namespace, _) {
          switch (namespace) {
            case 'ns1':
              return const {'key': 'My first value'};
            case 'ns2':
              return const {'key': 'My second value'};
          }
          return null;
        },
      );
    });

    test('given key for matching namespaces', () {
      expect(i18next.t('ns1:key'), 'My first value');
      expect(i18next.t('ns2:key'), 'My second value');
    });

    test('given key for unmatching namespaces', () {
      expect(i18next.t('ns3:key'), 'ns3:key');
    });

    test('given key for partially matching namespaces', () {
      expect(i18next.t('ns:key'), 'ns:key');
    });
  });

  test('given data source', () {
    i18next = I18Next(
      locale,
      expectAsync2((namespace, loc) {
        expect(namespace, 'ns');
        expect(loc, locale);
        return {'myKey': 'My value'};
      }, count: 1),
    );
    expect(i18next.t('ns:myKey'), 'My value');
  });

  test('given null namespace', () {
    given(null);
    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  test('given null key', () {
    given({});
    expect(() => i18next.t(null), throwsAssertionError);
  });

  test('given an existing string key', () {
    given({'myKey': 'This is my key'});
    expect(i18next.t('myKey'), 'This is my key');
  });

  test('given a non-existing key', () {
    given({});
    expect(i18next.t('someKey'), 'someKey');
    expect(i18next.t('some.key'), 'some.key');
  });

  group('given nested data', () {
    test('given a matching nested key', () {
      given({
        'my': {
          'key': 'This is my key',
          'nested': {
            'key': 'This is a more nested key',
          }
        }
      });
      expect(i18next.t('my.key'), 'This is my key');
      expect(i18next.t('my.nested.key'), 'This is a more nested key');
    });

    test('given a partially matching nested key', () {
      given({
        'my': {
          'nested': {'key': 'This is a more nested key'},
        }
      });
      expect(i18next.t('my'), 'my');
      expect(i18next.t('my.nested'), 'my.nested');
    });

    test('given a over matching nested key', () {
      given({
        'my': {
          'nested': {'key': 'This is a more nested key'},
        }
      });
      expect(i18next.t('my.nested.key.here'), 'my.nested.key.here');
    });
  });

  test('given overriding locale', () {
    const anotherLocale = Locale('another');
    i18next = I18Next(locale, expectAsync2((_, loc) {
      expect(loc, anotherLocale);
      return const {'key': 'my value'};
    }));
    expect(i18next.t('key', locale: anotherLocale), 'my value');
  });

  group('given formatter', () {
    test('with no interpolations', () {
      given(
        const {'key': 'no interpolations here'},
        formatter: expectAsync3((value, format, locale) => null, count: 0),
      );
      expect(i18next.t('key'), 'no interpolations here');
    });

    test('with no matching variables', () {
      given(
        const {'key': 'leading {{value, format}} trailing'},
        formatter: expectAsync3(
          (value, format, locale) => value.toString(),
          count: 0,
        ),
      );
      expect(
        i18next.t('key', variables: {'name': 'World'}),
        'leading {{value, format}} trailing',
      );
    });

    test('with matching variables', () {
      given(
        const {'myKey': 'leading {{value, format}} trailing'},
        formatter: expectAsync3((value, format, locale) => value.toString()),
      );
      expect(
        i18next.t('myKey', variables: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with one matching interpolation', () {
      given(
        const {'myKey': 'leading {{value, format}} trailing'},
        formatter: expectAsync3(
          (value, format, locale) {
            expect(value, 'eulav');
            expect(format, 'format');
            expect(locale, locale);
            return value.toString();
          },
        ),
      );
      expect(
        i18next.t('myKey', variables: {'value': 'eulav'}),
        'leading eulav trailing',
      );
    });

    test('with multiple matching interpolations', () {
      final values = <String>[];
      final formats = <String>[];
      given(
        const {
          'myKey': 'leading {{value1, format1}} middle '
              '{{value2, format2}} trailing'
        },
        formatter: expectAsync3(
          (value, format, locale) {
            values.add(value);
            formats.add(format);
            return value.toString();
          },
          count: 2,
        ),
      );
      expect(
        i18next.t('myKey', variables: {
          'value1': '1eulav',
          'value2': '2eulav',
        }),
        'leading 1eulav middle 2eulav trailing',
      );
      expect(values, orderedEquals(<String>['1eulav', '2eulav']));
      expect(formats, orderedEquals(<String>['format1', 'format2']));
    });
  });

  group('pluralization', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_plural': '{{count}} friends',
      });
    });

    test('given key without count', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given key with count', () {
      expect(i18next.t('friend', count: 0), '0 friends');
      expect(i18next.t('friend', count: 1), 'A friend');
      expect(i18next.t('friend', count: -1), '-1 friends');
      expect(i18next.t('friend', count: 99), '99 friends');
    });

    test('given key with count in variables', () {
      expect(i18next.t('friend', variables: {'count': 0}), '0 friends');
      expect(i18next.t('friend', variables: {'count': 1}), 'A friend');
      expect(i18next.t('friend', variables: {'count': -1}), '-1 friends');
      expect(i18next.t('friend', variables: {'count': 99}), '99 friends');
    });

    test('given key with both count property and in variables', () {
      expect(
        i18next.t('friend', count: 0, variables: {'count': 1}),
        'A friend',
      );
      expect(
        i18next.t('friend', count: 1, variables: {'count': 0}),
        '0 friends',
      );
    });

    test('given key with count and unmmaped context', () {
      expect(
        i18next.t('friend', count: 1, context: 'something'),
        'A friend',
      );
      expect(
        i18next.t('friend', count: 99, context: 'something'),
        '99 friends',
      );
    });

    // TODO: add special pluralization rules
  });

  group('contextualization', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_male': 'A boyfriend',
        'friend_female': 'A girlfriend',
      });
    });

    test('given key without context', () {
      expect(i18next.t('friend'), 'A friend');
    });

    test('given key with mapped context', () {
      expect(i18next.t('friend', context: 'male'), 'A boyfriend');
      expect(i18next.t('friend', context: 'female'), 'A girlfriend');
    });

    test('given key with mapped context in variables', () {
      expect(
        i18next.t('friend', variables: {'context': 'male'}),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', variables: {'context': 'female'}),
        'A girlfriend',
      );
    });

    test('given key with both mapped context property and in variables', () {
      expect(
        i18next.t('friend', context: 'female', variables: {'context': 'male'}),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'male', variables: {'context': 'female'}),
        'A girlfriend',
      );
    });

    test('given key with unmaped context', () {
      expect(i18next.t('friend', context: 'other'), 'A friend');
    });

    test('given key with mapped context and count', () {
      expect(
        i18next.t('friend', context: 'male', count: 0),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'male', count: 1),
        'A boyfriend',
      );
    });

    test('given key with unmapped context and count', () {
      expect(
        i18next.t('friend', context: 'other', count: 1),
        'A friend',
      );
      expect(
        i18next.t('friend', context: 'other', count: 99),
        'A friend',
      );
    });
  });

  group('contextualization and pluralization', () {
    setUp(() {
      given(const {
        'friend': 'A friend',
        'friend_plural': '{{count}} friends',
        'friend_male': 'A boyfriend',
        'friend_male_plural': '{{count}} boyfriends',
        'friend_female': 'A girlfriend',
        'friend_female_plural': '{{count}} girlfriends',
      });
    });

    test('given key with mapped context and count', () {
      expect(
        i18next.t('friend', context: 'male', count: 0),
        '0 boyfriends',
      );
      expect(
        i18next.t('friend', context: 'male', count: 1),
        'A boyfriend',
      );
      expect(
        i18next.t('friend', context: 'female', count: 0),
        '0 girlfriends',
      );
      expect(
        i18next.t('friend', context: 'female', count: 1),
        'A girlfriend',
      );
    });

    test('given key with unmmaped context and count', () {
      expect(
        i18next.t('friend', context: 'other', count: 0),
        '0 friends',
      );
      expect(
        i18next.t('friend', context: 'other', count: 1),
        'A friend',
      );
    });
  });

  group('interpolation', () {
    setUp(() {
      given(const {'myKey': '{{first}}, {{second}}, and then {{third}}!'});
    });

    test('given empty interpolation', () {
      given({'key': 'This is some {{}}'});
      expect(i18next.t('key'), 'This is some {{}}');
    });

    test('given non matching arguments', () {
      expect(
        i18next.t('myKey', variables: {'none': 'none'}),
        '{{first}}, {{second}}, and then {{third}}!',
      );
    });

    test('given partially matching arguments', () {
      expect(
        i18next.t('myKey', variables: {'first': 'fst'}),
        'fst, {{second}}, and then {{third}}!',
      );
      expect(
        i18next.t('myKey', variables: {'first': 'fst', 'third': 'trd'}),
        'fst, {{second}}, and then trd!',
      );
    });

    test('given all matching arguments', () {
      expect(
        i18next.t('myKey', variables: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
        }),
        'fst, snd, and then trd!',
      );
    });

    test('given extra matching arguments', () {
      expect(
        i18next.t('myKey', variables: {
          'first': 'fst',
          'second': 'snd',
          'third': 'trd',
          'none': 'none',
        }),
        'fst, snd, and then trd!',
      );
    });
  });

  group('nesting', () {
    test('when nested key is not found', () {
      given({'key': r'This is my $t(anotherKey)'});
      expect(i18next.t('key'), r'This is my $t(anotherKey)');
    });

    test('given multiple simple key substitutions', () {
      given({
        'nesting1': r'1 $t(nesting2)',
        'nesting2': r'2 $t(nesting3)',
        'nesting3': '3',
      });
      expect(i18next.t('nesting1'), '1 2 3');
    });

    test('interpolation from immediate variables', () {
      given({
        'key1': 'hello world',
        'key2': 'say: {{val}}',
      });
      expect(
        i18next.t('key2', variables: {'val': r'$t(key1)'}),
        'say: hello world',
      );
    });

    test('nested interpolations', () {
      given({
        'key1': 'hello {{name}}',
        'key2': r'say: $t(key1)',
      });
      expect(
        i18next.t('key2', variables: {'name': 'world'}),
        'say: hello world',
      );
    });

    test('nested pluralization and interpolation ', () {
      given({
        'girlsAndBoys': r'$t(girls, {"count": {{girls}} }) and {{count}} boy',
        'girlsAndBoys_plural':
            r'$t(girls, {"count": {{girls}} }) and {{count}} boys',
        'girls': "{{count}} girl",
        'girls_plural': "{{count}} girls"
      });
      expect(
        i18next.t('girlsAndBoys', count: 2, variables: {'girls': 3}),
        '3 girls and 2 boys',
      );
    });
  });
}
