import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk_algarve_app/views/helpers/connectivity_helper.dart';

const connectivityChannel =
    MethodChannel('dev.fluttercommunity.plus/connectivity');

void reportConnectivity(List<String> results) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(connectivityChannel, (_) async => results);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases = {
    'offline when only none is reported': (['none'], false),
    'offline when nothing is reported': (<String>[], false),
    'online on wifi': (['wifi'], true),
    'online on mobile data and vpn': (['mobile', 'vpn'], true),
  };

  cases.forEach((name, expected) {
    test('reports $name', () async {
      final (results, online) = expected;
      reportConnectivity(results);

      expect(await ConnectivityHelper.hasConnection(), online);
    });
  });
}
