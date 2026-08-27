import 'package:flutter/material.dart';
import 'package:skyjumper/features/home/home_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await PlayerProgressRepository.load();
  runApp(SkyJumperApp(progress: progress));
}

class SkyJumperApp extends StatelessWidget {
  const SkyJumperApp({
    super.key,
    required this.progress,
  });

  final PlayerProgressRepository progress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkyJumper',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A2E),
        ),
      ),
      home: HomeScreen(progress: progress),
    );
  }
}
