import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';
import 'package:skyjumper/widgets/skin_avatar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _entries = <_LeaderboardEntry>[
    _LeaderboardEntry('PASKO', 'custom_slot_16', 'Gubi', 12406463),
    _LeaderboardEntry('Anthonyburges', 'custom_slot_03', 'CoolBoy', 4905657),
    _LeaderboardEntry('KAMYON', 'custom_slot_20', 'Canary', 4682267),
    _LeaderboardEntry('Bedel55', 'custom_slot_18', 'Princess', 4525584),
    _LeaderboardEntry('nero', 'custom_slot_02', 'TheKing', 3869780),
    _LeaderboardEntry('nisa', 'custom_slot_18', 'Princess', 3452251),
    _LeaderboardEntry('ecoline', 'classic', 'Classic', 3115522),
    _LeaderboardEntry('Aerin', 'classic', 'Classic', 2156105),
    _LeaderboardEntry('fottuce', 'custom_slot_06', 'Pirate', 1047236),
  ];

  void _offlineInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu tablo eski Season 1 görünümünün çevrimdışı anlık görüntüsüdür.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051326),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('GLOBAL', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF06182D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3E789A)),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'GLOBAL LEADERBOARD',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: .7),
                            ),
                            SizedBox(height: 5),
                            Text('TOP 10 PLAYERS', style: TextStyle(color: Color(0xFF8FCBFF), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: _offlineInfo, icon: const Icon(Icons.history_rounded, color: Colors.white70)),
                      IconButton(onPressed: _offlineInfo, icon: const Icon(Icons.flag_rounded, color: Color(0xFFFFE263))),
                      IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 14, bottom: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16344D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF497D9D)),
                    ),
                    child: const Text('SEASON S1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _LeaderboardRow(rank: index + 1, entry: entry);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071F2A),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFF46B98A)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text('YOUR STANDING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                      const Text('#11,768', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      Text(
                        'BEST ${widget.progress.bestScore}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                      ),
                    ],
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

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});

  final int rank;
  final _LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final skin = skinById(entry.skinId);
    final rankColor = rank <= 3 ? const Color(0xFFFFDF55) : const Color(0xFFAED9FF);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F4668)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900)),
          ),
          SizedBox(width: 42, height: 48, child: SkinAvatar(skin: skin)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                Text(entry.skinName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Text(
            _format(entry.score),
            style: const TextStyle(color: Color(0xFFFFDD55), fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  static String _format(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}

class _LeaderboardEntry {
  const _LeaderboardEntry(this.name, this.skinId, this.skinName, this.score);

  final String name;
  final String skinId;
  final String skinName;
  final int score;
}
