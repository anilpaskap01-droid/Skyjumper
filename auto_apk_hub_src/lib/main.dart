import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoApkHubApp());
}

class AutoApkHubApp extends StatelessWidget {
  const AutoApkHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto APK Hub',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class CatalogItem {
  CatalogItem({required this.name, required this.url});

  final String name;
  final String url;

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  static CatalogItem? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final name = raw['name'];
    final url = raw['url'];
    if (name is! String || url is! String) return null;
    if (name.trim().isEmpty || url.trim().isEmpty) return null;
    return CatalogItem(name: name.trim(), url: url.trim());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const MethodChannel _channel = MethodChannel('auto_apk_hub/native');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final List<CatalogItem> _items = <CatalogItem>[];

  bool _busy = false;
  double? _progress;
  String _status = 'Hazır';

  File get _catalogFile =>
      File('${Directory.systemTemp.parent.path}/auto_apk_hub_catalog.json');

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      if (!await _catalogFile.exists()) return;
      final decoded = jsonDecode(await _catalogFile.readAsString());
      if (decoded is! List) return;
      final loaded = decoded
          .map(CatalogItem.fromJson)
          .whereType<CatalogItem>()
          .toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Bozuk katalog uygulamanın açılmasını engellemesin.
    }
  }

  Future<void> _saveCatalog() async {
    try {
      await _catalogFile.writeAsString(
        jsonEncode(_items.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  Uri? _validatedHttpsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty) {
      _showMessage('Uygulama adı yaz.');
      return;
    }
    if (_validatedHttpsUrl(url) == null) {
      _showMessage('Geçerli bir HTTPS APK bağlantısı yaz.');
      return;
    }
    setState(() {
      _items.add(CatalogItem(name: name, url: url));
      _nameController.clear();
      _urlController.clear();
    });
    await _saveCatalog();
  }

  Future<void> _removeItem(int index) async {
    setState(() => _items.removeAt(index));
    await _saveCatalog();
  }

  Future<bool> _ensureInstallPermission() async {
    try {
      final allowed =
          await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
      if (allowed) return true;

      if (!mounted) return false;
      final open = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Kurulum izni gerekli'),
              content: const Text(
                'Android, Auto APK Hub üzerinden APK kurmak için "Bu kaynaktan izin ver" onayı ister.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ayarı aç'),
                ),
              ],
            ),
          ) ??
          false;
      if (!open) return false;
      await _channel.invokeMethod('openUnknownSources');
      return false;
    } on PlatformException catch (e) {
      _showMessage(e.message ?? 'Kurulum izni kontrol edilemedi.');
      return false;
    }
  }

  Future<void> _pickLocalApk() async {
    if (!await _ensureInstallPermission()) return;
    try {
      await _channel.invokeMethod('pickAndInstallApk');
    } on PlatformException catch (e) {
      _showMessage(e.message ?? 'APK seçici açılamadı.');
    }
  }

  Future<void> _downloadAndInstall(CatalogItem item) async {
    final uri = _validatedHttpsUrl(item.url);
    if (uri == null) {
      _showMessage('Bu kayıt geçerli bir HTTPS adresi içermiyor.');
      return;
    }
    if (!await _ensureInstallPermission()) return;

    setState(() {
      _busy = true;
      _progress = null;
      _status = '${item.name} indiriliyor…';
    });

    HttpClient? client;
    IOSink? sink;
    File? outFile;

    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'AutoAPKHub/1.0');
      final response = await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Sunucu HTTP ${response.statusCode} döndürdü.');
      }

      final total = response.contentLength;
      const maxBytes = 500 * 1024 * 1024;
      if (total > maxBytes) {
        throw const FileSystemException('APK 500 MB sınırından büyük.');
      }

      final safeName = item.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      outFile = File(
        '${Directory.systemTemp.path}/${safeName.isEmpty ? 'download' : safeName}_${DateTime.now().millisecondsSinceEpoch}.apk',
      );
      sink = outFile.openWrite();

      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        if (received > maxBytes) {
          throw const FileSystemException('İndirme 500 MB sınırını aştı.');
        }
        sink.add(chunk);
        if (mounted) {
          setState(() {
            _progress = total > 0 ? received / total : null;
            _status = total > 0
                ? '${(received / 1048576).toStringAsFixed(1)} / ${(total / 1048576).toStringAsFixed(1)} MB'
                : '${(received / 1048576).toStringAsFixed(1)} MB indirildi';
          });
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (!await outFile.exists() || await outFile.length() < 4) {
        throw const FileSystemException('İndirilen dosya boş veya geçersiz.');
      }

      final raf = await outFile.open();
      final header = await raf.read(4);
      await raf.close();
      final zipLike = header.length >= 4 && header[0] == 0x50 && header[1] == 0x4B;
      if (!zipLike) {
        throw const FormatException(
          'İndirilen içerik APK değil. Doğrudan .apk bağlantısı kullan.',
        );
      }

      if (mounted) {
        setState(() => _status = 'Android paket yükleyici açılıyor…');
      }
      await _channel.invokeMethod('installDownloadedApk', {'path': outFile.path});
    } on TimeoutException {
      _showMessage('İndirme zaman aşımına uğradı.');
    } on SocketException catch (e) {
      _showMessage('Ağ hatası: ${e.message}');
    } on PlatformException catch (e) {
      _showMessage(e.message ?? 'Android paket yükleyici açılamadı.');
    } catch (e) {
      _showMessage('Hata: $e');
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close(force: true);
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _status = 'Hazır';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto APK Hub'),
        actions: [
          IconButton(
            tooltip: 'Bilinmeyen kaynak izni',
            onPressed: _busy
                ? null
                : () => _channel.invokeMethod('openUnknownSources'),
            icon: const Icon(Icons.security),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'AAAD benzeri APK yükleyici',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Doğrudan HTTPS APK bağlantısı ekleyebilir veya telefondaki bir APK dosyasını seçebilirsin. Her kurulum Android sistem onayıyla yapılır.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _pickLocalApk,
              icon: const Icon(Icons.folder_open),
              label: const Text('Telefondaki APK’yı seç ve yükle'),
            ),
            const SizedBox(height: 20),
            Text('Kataloğa uygulama ekle',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              enabled: !_busy,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Uygulama adı',
                hintText: 'Örn. Screen2Auto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Doğrudan HTTPS APK bağlantısı',
                hintText: 'https://.../uygulama.apk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _busy ? null : _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Kataloğa ekle'),
            ),
            if (_busy || _status != 'Hazır') ...[
              const SizedBox(height: 18),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_status),
            ],
            const SizedBox(height: 22),
            Text('Kayıtlı uygulamalar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Henüz kayıt yok. Güvendiğin kaynaktaki doğrudan APK bağlantısını yukarıdan ekle.',
                  ),
                ),
              )
            else
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(item.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        SelectableText(
                          item.url,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _downloadAndInstall(item),
                                icon: const Icon(Icons.download),
                                label: const Text('İndir / Yükle'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Sil',
                              onPressed: _busy ? null : () => _removeItem(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 18),
            Text(
              'Not: Bu uygulama Android güvenliğini veya Android Auto kısıtlamalarını aşmaz. Sadece normal, kullanıcı onaylı APK kurulumunu kolaylaştırır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
