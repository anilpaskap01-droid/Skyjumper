import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyjumper/features/home/home_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHomeAtSize(
    WidgetTester tester,
    Size logicalSize,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final progress = await PlayerProgressRepository.load();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(progress: progress)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('ENVANTER'), findsOneWidget);
  }

  testWidgets('home fits a compact portrait phone', (tester) async {
    await pumpHomeAtSize(tester, const Size(360, 800));
  });

  testWidgets('home fits a tall wide portrait phone', (tester) async {
    await pumpHomeAtSize(tester, const Size(430, 932));
  });
}
