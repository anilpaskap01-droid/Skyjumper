import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoMirrorApp());
}

class AutoMirrorApp extends StatelessWidget {
  const AutoMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoMirror Parked',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      home: const MirrorHome(),
    );
  }
}

class MirrorHome extends StatefulWidget {
  const MirrorHome({super.key});

  @override
  State<MirrorHome> createState() => _MirrorHomeState();
}

class _MirrorHomeState extends State<MirrorHome> {
  static const _channel = MethodChannel('auto_mirror/native');

  bool _externalDisplay = false;
  bool _running = false;
  bool _busy = true;
  Uint8List? _frame;
  Timer? _timer;
  String _status = 'Hazırlanıyor…';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _externalDisplay = await _channel.invokeMethod<bool>('isExternalDisplay') ?? false;
      _running = await _channel.invokeMethod<bool>('captureRunning') ?? false;
      if (_externalDisplay) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = _externalDisplay
          ? 'Telefon ekranı bekleniyor…'
          : (_running ? 'Yansıtma açık' : 'Hazır');
    });
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 140), (_) => _pollFrame());
  }

  Future<void> _pollFrame() async {
    if (!mounted) return;
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getFrame');
      final running = await _channel.invokeMethod<bool>('captureRunning') ?? false;
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _frame = bytes;
          _running = running;
          if (_externalDisplay) _status = 'Canlı';
        });
      } else if (_running != running) {
        setState(() => _running = running);
      }
    } catch (_) {}
  }

  Future<void> _startCapture() async {
    setState(() {
      _busy = true;
      _status = 'Ekran paylaşım izni açılıyor…';
    });
    try {
      await _channel.invokeMethod('startCapture');
      if (!mounted) return;
      setState(() => _status = 'Android ekran paylaşım penceresini onayla.');
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = e.message ?? 'Ekran paylaşımı başlatılamadı.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopCapture() async {
    try {
      await _channel.invokeMethod('stopCapture');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _running = false;
      _frame = null;
      _status = 'Durduruldu';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_externalDisplay) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: _frame == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 18),
                      Text(
                        _status,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Telefonda AutoMirror Parked uygulamasını açıp\n“Ekranı paylaş” düğmesine bas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                : InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 2.0,
                    child: Image.memory(
                      _frame!,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AutoMirror Parked')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Telefon ekranını araç ekranında gösterme denemesi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu sürüm Android Auto’nun park edilmiş uygulama ekranı üzerinden çalışacak şekilde hazırlanmıştır. Android Auto uygulamayı araç ekranında göstermiyorsa, ana ünitenin bu park modu uygulama tipini desteklemiyor demektir.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _startCapture,
            icon: const Icon(Icons.screen_share),
            label: const Text('Ekranı paylaş'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _running ? _stopCapture : null,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Yansıtmayı durdur'),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_running ? Icons.check_circle : Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_status)),
                ],
              ),
            ),
          ),
          if (_frame != null) ...[
            const SizedBox(height: 18),
            Text('Önizleme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Colors.black,
                  child: Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Kullanım: Önce telefonda ekran paylaşımını başlat. Sonra Android Auto uygulama ekranından AutoMirror Parked’i aç. Bu uygulama sürüş sırasında video kilidini aşmaya çalışmaz; park modu kısıtlamasını Android Auto uygular.',
          ),
        ],
      ),
    );
  }
}
