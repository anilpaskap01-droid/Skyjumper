import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyjumper/features/home/home_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final progress = await PlayerProgressRepository.load();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(home: HomeScreen(progress: progress)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home renders on tall phone', (tester) async {
    await _pumpHome(tester, const Size(412, 915));
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home renders on compact phone', (tester) async {
    await _pumpHome(tester, const Size(360, 720));
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all APK skins are unlocked locally', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final progress = await PlayerProgressRepository.load();
    expect(progress.ownedSkinIds.length, 37);
    expect(progress.gold, PlayerProgressRepository.unlimitedCurrency);
    expect(progress.gems, PlayerProgressRepository.unlimitedCurrency);
  });
}
