import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming || !widget.progress.canClaimDaily()) return;
    setState(() => _claiming = true);
    final result = await widget.progress.claimDailyReward();
    if (!mounted) return;
    setState(() => _claiming = false);
    if (result != null) {
      final gems = result.gems > 0 ? ' + ${result.gems} GEM' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.gold} GOLD$gems alındı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return Scaffold(
      backgroundColor: const Color(0xFF071326),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('GÜNLÜK ÖDÜLLER', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.25,
            colors: <Color>[Color(0xFF123963), Color(0xFF071326)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Column(
              children: <Widget>[
                const Text(
                  '7 GÜNLÜK SERİ',
                  style: TextStyle(color: Color(0xFF75E6FF), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seri: ${progress.dailyStreak}/7',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    itemCount: 7,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final claimed = day <= progress.dailyStreak && !progress.canClaimDaily();
                      final active = day == (progress.dailyStreak >= 7 ? 1 : progress.dailyStreak + 1) && progress.canClaimDaily();
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C203A),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            width: active ? 2 : 1,
                            color: active ? const Color(0xFF5DF09B) : Colors.white12,
                          ),
                          boxShadow: active
                              ? const <BoxShadow>[BoxShadow(color: Color(0x445DF09B), blurRadius: 18)]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('GÜN $day', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC93F), size: 34),
                            Text(
                              '${PlayerProgressRepository.dailyGoldRewards[index]} GOLD',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            if (PlayerProgressRepository.dailyGemRewards[index] > 0)
                              Text(
                                '+${PlayerProgressRepository.dailyGemRewards[index]} GEM',
                                style: const TextStyle(color: Color(0xFF80E9FF), fontWeight: FontWeight.w900),
                              ),
                            if (claimed)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.check_circle_rounded, color: Color(0xFF5DF09B)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: progress.canClaimDaily() && !_claiming ? _claim : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF38C86C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: Text(
                      progress.canClaimDaily() ? 'ÖDÜLÜ AL' : 'BUGÜN ALINDI',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
