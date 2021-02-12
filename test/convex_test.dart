import 'dart:convert' as convert;

import 'package:convex_wallet/convex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../lib/convex.dart' as convex;

const _TEST_ADDRESS =
    '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710f';

Future<http.Response> _query({
  String address = _TEST_ADDRESS,
  String source,
  convex.Lang lang = convex.Lang.convexLisp,
}) =>
    convex.queryRaw(
      source: source,
      lang: lang,
      address: address,
    );

Future<http.Response> _account({
  String address = _TEST_ADDRESS,
}) =>
    convex.getAccountRaw(
      address: convex.Address.fromHex(address),
    );

Future<http.Response> _faucet({
  String address,
  int amount,
}) =>
    convex.faucet(
      address: address,
      amount: amount,
    );

Future<http.Response> _prepareTransaction({
  String source,
  convex.Address address,
}) =>
    convex.prepareTransaction(
      source: source,
      address: address.hex,
    );

void main() {
  final convexClient = ConvexClient(
    server: convexWorldUri,
    client: http.Client(),
  );

  group('Convex Client', () {
    test('Prepare Transaction', () async {
      final response = await convexClient.prepareTransaction2(
        address: Address2(9),
        source: '(inc 1)',
      );

      Map body = convert.jsonDecode(response.body);

      expect(response.statusCode, 200);
      expect(body.keys.toSet(), {
        'sequence',
        'address',
        'source',
        'lang',
        'hash',
      });
    });
  });

  group('Account', () {
    test('Details', () async {
      var response = await _account(address: _TEST_ADDRESS);

      Map body = convert.jsonDecode(response.body);

      expect(response.statusCode, 200);
      expect(body.keys.toSet(), {
        'environment',
        'address',
        'is_library',
        'is_actor',
        'memory_size',
        'balance',
        'allowance',
        'sequence',
        'type',
      });
    });

    test('Not found', () async {
      var response = await _account(
          address:
              '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710d');

      expect(response.statusCode, 404);
    });
  });

  group('Query - Convex Lisp', () {
    test('Inc', () async {
      var response = await _query(source: '(inc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await _query(source: '*address*');

      expect(response.statusCode, 200);
      expect(
        convert.jsonDecode(response.body),
        {'value': _TEST_ADDRESS},
      );
    });

    test('Error - UNDECLARED', () async {
      var response = await _query(source: '(incc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body)['error-code'], 'UNDECLARED');
    });

    test('Error - CAST', () async {
      var response = await _query(source: '(map inc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body)['error-code'], 'CAST');
    });
  });

  group('Query - Convex Scrypt', () {
    test('Inc', () async {
      var response = await _query(
        source: 'inc(1)',
        lang: convex.Lang.convexScript,
      );

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await _query(
        source: '_address_',
        lang: convex.Lang.convexScript,
      );

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': _TEST_ADDRESS});
    });
  });

  group('Transaction', () {
    test('Prepare', () async {
      var response = await _prepareTransaction(
        address: convex.Address.fromHex(_TEST_ADDRESS),
        source: '(inc 1)',
      );

      Map body = convert.jsonDecode(response.body);

      expect(response.statusCode, 200);
      expect(body.keys.toSet(), {
        'sequence_number',
        'address',
        'source',
        'lang',
        'hash',
      });
    });
  });

  test('Faucet', () async {
    var response = await _faucet(
      address: _TEST_ADDRESS,
      amount: 1000,
    );

    expect(response.statusCode, 200);

    Map body = convert.jsonDecode(response.body);

    expect(body.keys.toSet(), {
      'address',
      'amount',
      'id',
      'value',
    });
  });
}
